const fs = require('fs');
const files = fs.readdirSync('.').filter(f => f.endsWith('.html') || f.endsWith('.js'));
const map = {
  '🏢': '🏢',
  '🎯': '🎯',
  '📦': '📦',
  '🗺️': '🗺️',
  '📋': '📋',
  '🔒': '🔒',
  '🛂': '🛂',
  '🚚': '🚚',
  '✈️': '✈️',
  '🚢': '🚢',
  '🚌': '🚌',
  '🚂': '🚂',
  '📄': '📄',
  '🔗': '🔗',
  '🔄': '🔄',
  '🔍': '🔍',
  '📍': '📍',
  '—': '—',
  '–': '–',
  '“': '“',
  '”': '”',
  '’': '’'
};

files.forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  let original = content;
  
  for (const [bad, good] of Object.entries(map)) {
    content = content.split(bad).join(good);
  }

  if (content !== original) {
    fs.writeFileSync(f, content, 'utf8');
    console.log('Fixed encoding in', f);
  }
});
