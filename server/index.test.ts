import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { createApp } from './index';

const app = createApp();

async function login(email: string, password: string) {
  const res = await request(app).post('/api/auth/login').send({ email, password }).expect(200);
  return res.body.token as string;
}

function bearer(token: string) {
  return { Authorization: `Bearer ${token}` };
}

let customerToken = '';
let restaurantToken = '';
let adminToken = '';

beforeAll(async () => {
  customerToken = await login('customer@savemeal.kg', 'Customer123!');
  restaurantToken = await login('restaurant@savemeal.kg', 'Restaurant123!');
  adminToken = await login('admin@savemeal.kg', 'Admin123!');
});

describe('SaveMeal MVP API', () => {
  it('authenticates a demo customer and blocks admin access', async () => {
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ email: 'customer@savemeal.kg', password: 'Customer123!' })
      .expect(200);

    expect(loginRes.body.user.role).toBe('customer');
    expect(loginRes.body.token).toBeTruthy();

    await request(app)
      .get('/api/admin/overview')
      .set('Authorization', `Bearer ${loginRes.body.token}`)
      .expect(403);
  });

  it('registers a new restaurant account and returns a pending approval status', async () => {
    const uniqueEmail = `restaurant-${Date.now()}@savemeal.kg`;

    const registerRes = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Новый ресторан',
        email: uniqueEmail,
        password: 'Restaurant123!',
        role: 'restaurant',
      })
      .expect(201);

    expect(registerRes.body.user.role).toBe('restaurant');
    expect(registerRes.body.user.approved).toBe(false);

    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${registerRes.body.token}`)
      .expect(200);

    expect(meRes.body.user.email).toBe(uniqueEmail);
    expect(meRes.body.user.role).toBe('restaurant');
  });
});

describe('Catalog visibility and filters', () => {
  let listingId = 0;

  it('hides listings on moderation from customers', async () => {
    const createRes = await request(app)
      .post('/api/listings')
      .set(bearer(restaurantToken))
      .send({
        title: 'Фильтр-тест #1',
        description: 'Объявление для проверки серверных фильтров каталога.',
        category: 'Тестовый фильтр',
        serviceType: 'sale',
        price: 550,
        originalPrice: 900,
        portions: 5,
        pickupWindow: 'Сегодня 18:00-20:00',
        deliveryAvailable: true,
        deliveryFee: 80,
        deliveryArea: 'Центр',
      })
      .expect(201);

    listingId = createRes.body.item.id;
    expect(createRes.body.item.status).toBe('pending_review');

    const asCustomer = await request(app).get('/api/listings').set(bearer(customerToken)).expect(200);
    expect(asCustomer.body.items.some((item: { id: number }) => item.id === listingId)).toBe(false);
  });

  it('applies server-side category and price filters', async () => {
    await request(app)
      .post('/api/admin/listings/moderate')
      .set(bearer(adminToken))
      .send({ listingId, decision: 'approve' })
      .expect(200);

    const byCategory = await request(app)
      .get('/api/listings')
      .query({ category: 'Тестовый фильтр' })
      .set(bearer(customerToken))
      .expect(200);

    expect(byCategory.body.items.some((item: { id: number }) => item.id === listingId)).toBe(true);
    expect(byCategory.body.items.every((item: { category: string }) => item.category === 'Тестовый фильтр')).toBe(true);

    const tooCheap = await request(app)
      .get('/api/listings')
      .query({ category: 'Тестовый фильтр', maxPrice: 100 })
      .set(bearer(customerToken))
      .expect(200);
    expect(tooCheap.body.items.length).toBe(0);

    const expensive = await request(app)
      .get('/api/listings')
      .query({ category: 'Тестовый фильтр', maxPrice: 600 })
      .set(bearer(customerToken))
      .expect(200);
    expect(expensive.body.items.some((item: { id: number }) => item.id === listingId)).toBe(true);
  });

  it('never leaks the real name of an anonymous restaurant', async () => {
    const createRes = await request(app)
      .post('/api/listings')
      .set(bearer(restaurantToken))
      .send({
        title: 'Анонимный ланч',
        description: 'Объявление с скрытым именем ресторана для проверки приватности.',
        category: 'Тест анонимности',
        serviceType: 'sale',
        price: 200,
        originalPrice: 300,
        portions: 3,
        pickupWindow: 'Сегодня до 21:00',
        isAnonymous: true,
      })
      .expect(201);

    const anonymousId = createRes.body.item.id;

    await request(app)
      .post('/api/admin/listings/moderate')
      .set(bearer(adminToken))
      .send({ listingId: anonymousId, decision: 'approve' })
      .expect(200);

    const asCustomer = await request(app).get(`/api/listings/${anonymousId}`).set(bearer(customerToken)).expect(200);
    expect(asCustomer.body.item.restaurant_name).toBe('Анонимный партнер');
    expect(JSON.stringify(asCustomer.body)).not.toContain('Кызыл Бешек');
    expect(asCustomer.body.item.actual_restaurant_name).toBeUndefined();

    const asAdmin = await request(app).get(`/api/listings/${anonymousId}`).set(bearer(adminToken)).expect(200);
    expect(asAdmin.body.item.restaurant_name).toContain('Кызыл Бешек');
  });

  it('rejects a listing with a mandatory reason', async () => {
    const createRes = await request(app)
      .post('/api/listings')
      .set(bearer(restaurantToken))
      .send({
        title: 'Объявление для отклонения',
        description: 'Это объявление модератор должен отклонить с указанием причины.',
        category: 'Тест отклонения',
        serviceType: 'sale',
        price: 100,
        originalPrice: 150,
        portions: 2,
        pickupWindow: 'Завтра',
      })
      .expect(201);

    await request(app)
      .post('/api/admin/listings/moderate')
      .set(bearer(adminToken))
      .send({ listingId: createRes.body.item.id, decision: 'reject', reason: 'Не указаны аллергены' })
      .expect(200);

    const detail = await request(app).get(`/api/listings/${createRes.body.item.id}`).set(bearer(adminToken)).expect(200);
    expect(detail.body.item.status).toBe('suspended');
    expect(detail.body.item.rejection_reason).toBe('Не указаны аллергены');
  });
});

describe('Order pricing and lifecycle', () => {
  let listingId = 0;
  let listingCat = '';

  beforeAll(async () => {
    listingCat = `Заказ-тест-${Date.now()}`;
    const createRes = await request(app)
      .post('/api/listings')
      .set(bearer(restaurantToken))
      .send({
        title: 'Заказ с доставкой',
        description: 'Объявление для проверки расчёта доставки и жизненного цикла заказа.',
        category: listingCat,
        serviceType: 'sale',
        price: 100,
        originalPrice: 200,
        portions: 20,
        pickupWindow: 'Сегодня',
        deliveryAvailable: true,
        deliveryFee: 80,
        deliveryArea: 'Центр',
      })
      .expect(201);

    listingId = createRes.body.item.id;
    await request(app).post('/api/admin/listings/moderate').set(bearer(adminToken)).send({ listingId, decision: 'approve' }).expect(200);
  });

  it('adds the delivery fee to the order total', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set(bearer(customerToken))
      .send({ listingId, quantity: 2, pickupType: 'delivery', deliveryAddress: 'ул. Чуй, 12, кв. 3' })
      .expect(201);

    expect(res.body.order.total_price).toBe(280);
    expect(res.body.breakdown).toEqual({ subtotal: 200, deliveryFee: 80, total: 280 });
  });

  it('does not charge delivery for pickup orders', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set(bearer(customerToken))
      .send({ listingId, quantity: 1, pickupType: 'pickup' })
      .expect(201);

    expect(res.body.order.total_price).toBe(100);
  });

  it('rejects delivery without an address', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set(bearer(customerToken))
      .send({ listingId, quantity: 1, pickupType: 'delivery', deliveryAddress: '' })
      .expect(400);
    expect(res.body.message).toContain('адрес');
  });

  it('blocks invalid status transitions', async () => {
    const orderRes = await request(app)
      .post('/api/orders')
      .set(bearer(customerToken))
      .send({ listingId, quantity: 1, pickupType: 'pickup' })
      .expect(201);

    await request(app)
      .patch(`/api/orders/${orderRes.body.order.id}/status`)
      .set(bearer(restaurantToken))
      .send({ status: 'completed' })
      .expect(400);
  });

  it('returns portions when a customer cancels', async () => {
    const before = await request(app).get(`/api/listings/${listingId}`).expect(200);
    const portionsBefore = before.body.item.available_portions;

    const orderRes = await request(app)
      .post('/api/orders')
      .set(bearer(customerToken))
      .send({ listingId, quantity: 3, pickupType: 'pickup' })
      .expect(201);

    const during = await request(app).get(`/api/listings/${listingId}`).expect(200);
    expect(during.body.item.available_portions).toBe(portionsBefore - 3);

    await request(app)
      .patch(`/api/orders/${orderRes.body.order.id}/status`)
      .set(bearer(customerToken))
      .send({ status: 'cancelled' })
      .expect(200);

    const after = await request(app).get(`/api/listings/${listingId}`).expect(200);
    expect(after.body.item.available_portions).toBe(portionsBefore);
  });

  it('walks the happy path restaurant transitions', async () => {
    const orderRes = await request(app)
      .post('/api/orders')
      .set(bearer(customerToken))
      .send({ listingId, quantity: 1, pickupType: 'pickup' })
      .expect(201);

    const orderId = orderRes.body.order.id;
    for (const status of ['confirmed', 'preparing', 'ready', 'completed']) {
      await request(app)
        .patch(`/api/orders/${orderId}/status`)
        .set(bearer(restaurantToken))
        .send({ status })
        .expect(200);
    }
  });
});

describe('Role boundaries', () => {
  it('forbids customers from creating listings and using admin endpoints', async () => {
    await request(app)
      .post('/api/listings')
      .set(bearer(customerToken))
      .send({
        title: 'Нельзя',
        description: 'Покупатель не должен уметь создавать объявления.',
        category: 'Тест',
        serviceType: 'sale',
        price: 1,
        originalPrice: 2,
        portions: 1,
        pickupWindow: 'Сегодня',
      })
      .expect(403);

    await request(app).get('/api/admin/listings').set(bearer(customerToken)).expect(403);
    await request(app).get('/api/donations/requests/my').set(bearer(customerToken)).expect(403);
    await request(app).get('/api/donations/requests/received').set(bearer(customerToken)).expect(403);
    await request(app).post('/api/admin/complaints/1/status').set(bearer(customerToken)).send({ status: 'resolved' }).expect(403);
  });

  it('forbids restaurants from moderating listings', async () => {
    await request(app)
      .post('/api/admin/listings/moderate')
      .set(bearer(restaurantToken))
      .send({ listingId: 1, decision: 'approve' })
      .expect(403);
  });

  it('does not expose demo credentials outside development', async () => {
    const res = await request(app).get('/api/demo/seed-info');
    expect([200, 404]).toContain(res.status);
    if (process.env.NODE_ENV !== 'development') expect(res.status).toBe(404);
  });
});

describe('Public statistics', () => {
  it('returns real platform metrics', async () => {
    const res = await request(app).get('/api/stats').expect(200);
    expect(typeof res.body.publishedListings).toBe('number');
    expect(typeof res.body.mealsRescued).toBe('number');
    expect(typeof res.body.donatedPortions).toBe('number');
    expect(res.body.publishedListings).toBeGreaterThan(0);
  });
});
