import express from 'express';

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: '${{ values.name }}' });
});

app.get('/', (_req, res) => {
  res.json({ message: 'Welcome to ${{ values.name }}' });
});

app.listen(port, () => {
  console.log(`${{ values.name }} running on port ${port}`);
});
