# ${{ values.name }}

${{ values.description }}

## Desenvolvimento

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
npm start
```

## Docker

```bash
docker build -t ${{ values.name }} .
docker run -p 3000:3000 ${{ values.name }}
```
