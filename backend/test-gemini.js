require('dotenv').config();

async function testModel(model) {
  const apiKey = process.env.GEMINI_API_KEY;
  const url = `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${apiKey}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: 'Say hello' }] }]
    })
  });
  const data = await res.json();
  console.log(`Response from ${model}:`, data);
}

// Replace with a model from the list
testModel('gemma-4-26b-a4b-it');