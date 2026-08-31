require('dotenv').config();

async function listModels() {
  const apiKey = process.env.GEMINI_API_KEY;
  const url = `https://generativelanguage.googleapis.com/v1/models?key=${apiKey}`;
  const res = await fetch(url);
  const data = await res.json();
  console.log('Available models:', data.models?.map(m => m.name) || data);
}

listModels();