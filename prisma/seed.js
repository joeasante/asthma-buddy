const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

async function main() {
  console.log('Seeding database...')

  // Seed symptoms
  const symptoms = [
    { name: 'Wheezing', description: 'High-pitched whistling sound when breathing', icon: 'wind', sort_order: 1 },
    { name: 'Coughing', description: 'Persistent or recurring cough', icon: 'activity', sort_order: 2 },
    { name: 'Chest Tightness', description: 'Feeling of pressure or constriction in chest', icon: 'heart', sort_order: 3 },
    { name: 'Shortness of Breath', description: 'Difficulty breathing or feeling breathless', icon: 'zap', sort_order: 4 },
    { name: 'Sleep Disruption', description: 'Waking up due to asthma symptoms', icon: 'moon', sort_order: 5 }
  ]

  for (const symptom of symptoms) {
    await prisma.symptom.upsert({
      where: { name: symptom.name },
      update: {},
      create: symptom,
    })
  }

  // Seed triggers
  const triggers = [
    { name: 'Pollen', description: 'Tree, grass, or weed pollen', category: 'ENVIRONMENTAL', icon: 'flower', sort_order: 1 },
    { name: 'Dust Mites', description: 'House dust mites', category: 'ENVIRONMENTAL', icon: 'home', sort_order: 2 },
    { name: 'Pet Dander', description: 'Cat, dog, or other pet allergens', category: 'ENVIRONMENTAL', icon: 'heart', sort_order: 3 },
    { name: 'Smoke', description: 'Cigarette smoke or other smoke', category: 'CHEMICAL', icon: 'cloud', sort_order: 4 },
    { name: 'Exercise', description: 'Physical activity or exertion', category: 'LIFESTYLE', icon: 'activity', sort_order: 5 },
    { name: 'Cold Air', description: 'Cold weather or air conditioning', category: 'WEATHER', icon: 'thermometer', sort_order: 6 },
    { name: 'Stress', description: 'Emotional stress or anxiety', category: 'LIFESTYLE', icon: 'brain', sort_order: 7 },
    { name: 'Strong Odors', description: 'Perfumes, cleaning products, etc.', category: 'CHEMICAL', icon: 'nose', sort_order: 8 },
    { name: 'Weather Changes', description: 'Barometric pressure changes', category: 'WEATHER', icon: 'cloud-rain', sort_order: 9 },
    { name: 'Respiratory Infection', description: 'Cold, flu, or other infections', category: 'MEDICAL', icon: 'thermometer', sort_order: 10 }
  ]

  for (const trigger of triggers) {
    await prisma.trigger.upsert({
      where: { name: trigger.name },
      update: {},
      create: trigger,
    })
  }

  console.log('Database seeded successfully!')
}

main()
  .then(async () => {
    await prisma.$disconnect()
  })
  .catch(async (e) => {
    console.error('Error seeding database:', e)
    await prisma.$disconnect()
    process.exit(1)
  })