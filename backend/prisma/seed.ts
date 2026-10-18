import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  const passwordHash = await bcrypt.hash('password123', 11);

  // 1. Create Mom (Owner)
  const mom = await prisma.user.upsert({
    where: { email: 'mom@example.com' },
    update: {},
    create: {
      name: 'Sarah (Mom)',
      email: 'mom@example.com',
      phone: '+972501234567',
      phoneKey: '501234567',
      passwordHash,
      locale: 'en',
    },
  });

  // 2. Create Dad (Caregiver)
  const dad = await prisma.user.upsert({
    where: { email: 'dad@example.com' },
    update: {},
    create: {
      name: 'David (Dad)',
      email: 'dad@example.com',
      phone: '+972509876543',
      phoneKey: '509876543',
      passwordHash,
      locale: 'he',
    },
  });

  console.log('✅ Created users:');
  console.log('   - mom@example.com / password123 (or phone: +972501234567)');
  console.log('   - dad@example.com / password123 (or phone: +972509876543)');

  // 3. Create Baby Liam
  let baby = await prisma.baby.findFirst({
    where: { name: 'Liam' },
  });

  if (!baby) {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    baby = await prisma.baby.create({
      data: {
        name: 'Liam',
        gender: 'boy',
        avatarColor: '#FF7A7A',
        birthDate: threeMonthsAgo,
        members: {
          create: [
            { userId: mom.id, role: 'OWNER' },
            { userId: dad.id, role: 'CAREGIVER' },
          ],
        },
      },
    });
    console.log('✅ Created Baby: Liam');
  }

  // 4. Create sample entries for today
  const now = new Date();
  const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);
  const fourHoursAgo = new Date(now.getTime() - 4 * 60 * 60 * 1000);
  const sixHoursAgo = new Date(now.getTime() - 6 * 60 * 60 * 1000);
  const sevenHoursAgo = new Date(now.getTime() - 7 * 60 * 60 * 1000);

  const existingEntries = await prisma.entry.count({ where: { babyId: baby.id } });
  if (existingEntries === 0) {
    // Feed 1: Morning Bottle
    await prisma.entry.create({
      data: {
        babyId: baby.id,
        createdById: mom.id,
        type: 'FEED',
        startedAt: sixHoursAgo,
        data: { method: 'bottle', amountMl: 140 },
        note: 'Drank the whole bottle happily',
      },
    });

    // Diaper 1: Wet & Dirty
    await prisma.entry.create({
      data: {
        babyId: baby.id,
        createdById: dad.id,
        type: 'DIAPER',
        startedAt: fourHoursAgo,
        data: { kind: 'mixed' },
      },
    });

    // Completed Morning Nap: 1h 15m
    await prisma.entry.create({
      data: {
        babyId: baby.id,
        createdById: mom.id,
        type: 'SLEEP',
        startedAt: sevenHoursAgo,
        endedAt: new Date(sevenHoursAgo.getTime() + 75 * 60 * 1000),
        data: {},
      },
    });

    // Feed 2: Afternoon feeding
    await prisma.entry.create({
      data: {
        babyId: baby.id,
        createdById: dad.id,
        type: 'FEED',
        startedAt: twoHoursAgo,
        data: { method: 'breast', side: 'both' },
        note: '15 mins each side',
      },
    });

    // Medicine: Vitamin D
    await prisma.entry.create({
      data: {
        babyId: baby.id,
        createdById: mom.id,
        type: 'MEDICINE',
        startedAt: fourHoursAgo,
        data: { name: 'Vitamin D', dose: '2 drops', isVaccine: false },
      },
    });

    console.log('✅ Created sample entries for Liam (feeding, sleep, diaper, medicine)');
  }

  // 5. Create Reminder
  const existingRem = await prisma.reminder.findFirst({ where: { babyId: baby.id, userId: mom.id } });
  if (!existingRem) {
    await prisma.reminder.create({
      data: {
        babyId: baby.id,
        userId: mom.id,
        kind: 'AFTER_LAST',
        entryType: 'FEED',
        intervalMinutes: 180,
        title: 'Feed Liam (every 3 hours)',
        enabled: true,
      },
    });
    console.log('✅ Created sample reminder for Mom');
  }

  // 6. Create sample Notification
  const existingNotif = await prisma.notification.findFirst({ where: { userId: dad.id } });
  if (!existingNotif) {
    await prisma.notification.create({
      data: {
        userId: dad.id,
        babyId: baby.id,
        title: '🍼 Liam',
        body: 'Sarah (Mom) logged a feeding',
        data: { type: 'entry' },
      },
    });
  }

  console.log('🎉 Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
