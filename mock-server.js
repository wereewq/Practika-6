const http = require('http');
const url = require('url');

const args = process.argv.slice(2);
let port = 8080;
let allowedOrigin = 'http://localhost:5555';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--port' && args[i + 1]) port = parseInt(args[i + 1], 10);
  if (args[i] === '--origin' && args[i + 1]) allowedOrigin = args[i + 1];
}

let users = [
  { id: 1, username: 'admin', password: 'Password123!', fullName: 'Главный Администратор', role: 'admin' },
  { id: 2, username: 'librarian', password: 'Password123!', fullName: 'Мария Библиотекарь', role: 'librarian' },
  { id: 3, username: 'reader', password: 'Password123!', fullName: 'Иван Читатель', role: 'reader' },
];

let db = {
  publishers: [{ id: 1, name: 'Азбука', city: 'СПб', website: 'https://azbooka.ru', deletedAt: null }],
  genres: [{ id: 1, name: 'Роман', description: 'Худ. лит', deletedAt: null }],
  authors: [{ id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828, deletedAt: null }],
  books: [{ id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 480, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 5, copiesAvailable: 3, deletedAt: null }],
  readers: [{ id: 1, fullName: 'Иван Иванов', email: 'ivanov@example.com', phone: '+79991112233', card: { cardNumber: 'CARD-1001', issuedAt: new Date().toISOString(), expiresAt: new Date().toISOString(), isActive: true }, deletedAt: null }]
};

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(data, null, 2));
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  console.log(`[Mock Server] ${req.method} ${path}`);

  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': allowedOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    return res.end();
  }

  let body = '';
  req.on('data', c => { body += c; });
  req.on('end', () => {
    let data = {};
    if (body) { try { data = JSON.parse(body); } catch (_) {} }

    // AUTH ЭНДПОИНТЫ
    if (path === '/api/auth/login' && req.method === 'POST') {
      const user = users.find(u => u.username === data.username && u.password === data.password);
      if (!user) return sendJson(res, 401, { message: 'Неверный логин или пароль' });
      return sendJson(res, 200, {
        accessToken: `fake-jwt-${user.username}-${user.role}`,
        refreshToken: `refresh-${user.username}`,
        user: { id: user.id, username: user.username, fullName: user.fullName, role: user.role }
      });
    }

    if (path === '/api/auth/register' && req.method === 'POST') {
      const newUser = { id: users.length + 1, username: data.username, password: data.password, fullName: data.fullName, role: data.role || 'reader' };
      users.push(newUser);
      return sendJson(res, 201, {
        accessToken: `fake-jwt-${newUser.username}-${newUser.role}`,
        refreshToken: `refresh-${newUser.username}`,
        user: { id: newUser.id, username: newUser.username, fullName: newUser.fullName, role: newUser.role }
      });
    }

    if (path === '/api/auth/me') {
      const authHeader = req.headers['authorization'] || '';
      const match = authHeader.match(/fake-jwt-([a-zA-Z0-9]+)-([a-zA-Z0-9]+)/);
      if (!match) return sendJson(res, 401, { message: 'Сессия истекла' });
      const user = users.find(u => u.username === match[1]);
      if (!user) return sendJson(res, 401, { message: 'Пользователь не найден' });
      return sendJson(res, 200, { id: user.id, username: user.username, fullName: user.fullName, role: user.role });
    }

    if (path === '/api/auth/refresh') {
      return sendJson(res, 200, {
        accessToken: `fake-jwt-refreshed`,
        refreshToken: `refresh-new`,
        user: users[0]
      });
    }

    // СЕРВЕРНАЯ ПРОВЕРКА РОЛЕЙ: Настоящая защита на сервере!
    const authHeader = req.headers['authorization'] || '';
    const match = authHeader.match(/fake-jwt-([a-zA-Z0-9]+)-([a-zA-Z0-9]+)/);
    const userRole = match ? match[2] : 'reader';

    // Читателю запрещено удалять книги или вызывать любые мутации
    if ((req.method === 'DELETE' || req.method === 'POST' || req.method === 'PUT') && !path.startsWith('/api/auth')) {
      if (userRole === 'reader') {
        return sendJson(res, 403, { message: 'Доступ запрещён: роль Читателя не может изменять данные на сервере!' });
      }
    }

    // Стандартные эндпоинты ПР4
    const cleanPath = path.replace(/^\/api(\/|$)/, '').replace(/^\/+|\/+$/g, '');
    const entity = cleanPath.split('/')[0];
    if (db[entity]) {
      if (req.method === 'GET') {
        return sendJson(res, 200, { items: db[entity], page: 1, size: 10, total: db[entity].length });
      }
      return sendJson(res, 200, { message: 'OK' });
    }

    sendJson(res, 404, { message: 'Не найдено' });
  });
});

server.listen(port, () => {
  console.log(`[Mock Server ПР5] Запущен на порту ${port}`);
});
