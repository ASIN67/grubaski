import { cp, mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const [buildDir, outputDir, revision] = process.argv.slice(2);
if (!buildDir || !outputDir || !/^[a-f0-9]{7,40}$/.test(revision ?? '')) {
  throw new Error('Usage: node deploy/build-pages.mjs <Flutter build> <new output directory> <commit SHA>');
}

const deployDir = fileURLToPath(new URL('.', import.meta.url));
const site = join(deployDir, 'site');
const flutter = resolve(buildDir);
const output = resolve(outputDir);
const app = join(output, 'app');
const read = (path) => readFile(path, 'utf8');

const [flutterHtml, bootstrap, hostHtml, workerTemplate, manifestJson] = await Promise.all([
  read(join(flutter, 'index.html')),
  read(join(flutter, 'flutter_bootstrap.js')),
  read(join(site, 'app', 'index.html')),
  read(join(deployDir, 'flutter_service_worker.js')),
  read(join(site, 'app', 'manifest.json')),
]);

const loaderStart = bootstrap.lastIndexOf('_flutter.loader.load(');
const headEnd = flutterHtml.indexOf('</head>');
const entryPoint = '"mainJsPath":"main.dart.js"';
if (!flutterHtml.includes('<base href="/app/">') || headEnd < 0 ||
    loaderStart < 0 || !bootstrap.includes(entryPoint)) {
  throw new Error('Expected a Flutter JavaScript release built for /app/.');
}

const headScripts = flutterHtml.slice(0, headEnd).match(/<script\b[^>]*>[\s\S]*?<\/script>/g) ?? [];
const manifest = JSON.parse(manifestJson);
for (const icon of manifest.icons) {
  icon.src = icon.src.split('?')[0] + '?v=' + revision;
}

await mkdir(output);
await cp(site, output, { recursive: true });
await cp(flutter, app, { recursive: true });

const appFiles = await readdir(app, { recursive: true, withFileTypes: true });
const shellFiles = [
  './',
  ...appFiles.filter((file) => file.isFile())
    .map((file) => relative(app, join(file.parentPath, file.name)).split(sep).join('/'))
    .filter((file) => file !== 'index.html' && file !== 'flutter_service_worker.js')
    .sort(),
];

const shellLoader = await read(join(deployDir, 'load-app.js'));
await Promise.all([
  writeFile(join(app, 'index.html'), hostHtml
    .replace('<!-- FLUTTER_HEAD_SCRIPTS -->', () => headScripts.join('\n'))
    .replaceAll('__REVISION__', revision)),
  writeFile(join(app, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n'),
  writeFile(join(app, 'flutter_bootstrap.js'), bootstrap.slice(0, loaderStart)
    .replace(entryPoint, `"mainJsPath":"main.dart.js?v=${revision}"`) + shellLoader),
  writeFile(join(app, 'flutter_service_worker.js'), workerTemplate
    .replace('__REVISION__', revision)
    .replace('__SHELL_FILES__', JSON.stringify(shellFiles, null, 2))),
]);
