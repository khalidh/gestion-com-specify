import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = path.dirname(fileURLToPath(import.meta.url));
const publicRoot = path.join(projectRoot, 'public');
const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
};

const server = createServer(async (request, response) => {
  const requestPath = new URL(request.url ?? '/', 'http://localhost').pathname;
  let decodedPath;

  try {
    decodedPath = decodeURIComponent(requestPath);
  } catch {
    response.writeHead(400).end('Requête invalide');
    return;
  }

  const filePath = decodedPath === '/'
    ? path.join(publicRoot, 'index.html')
    : path.resolve(publicRoot, `.${decodedPath}`);

  if (filePath !== path.join(publicRoot, 'index.html') && !filePath.startsWith(`${publicRoot}${path.sep}`)) {
    response.writeHead(403).end('Accès interdit');
    return;
  }

  try {
    const content = await readFile(filePath);
    response.writeHead(200, {
      'Content-Type': mimeTypes[path.extname(filePath)] ?? 'application/octet-stream',
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'no-store',
    });
    response.end(content);
  } catch {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }).end('Page introuvable');
  }
});

const port = Number(process.env.PORT ?? 4173);
server.listen(port, '127.0.0.1', () => {
  console.log(`Prototype disponible sur http://localhost:${port}`);
});