import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Clear existing data
  await prisma.comment.deleteMany({});
  await prisma.task.deleteMany({});
  await prisma.project.deleteMany({});
  await prisma.user.deleteMany({});

  // Create sample users
  const user1 = await prisma.user.create({
    data: {
      name: 'Alice Johnson',
      email: 'alice@example.com',
      role: 'ADMIN',
    },
  });

  const user2 = await prisma.user.create({
    data: {
      name: 'Bob Smith',
      email: 'bob@example.com',
      role: 'USER',
    },
  });

  console.log('✅ Created', user1, user2);

  // Create sample projects
  const project1 = await prisma.project.create({
    data: {
      title: 'Thanos Platform',
      description: 'Full stack development platform',
      ownerId: user1.id,
    },
  });

  const project2 = await prisma.project.create({
    data: {
      title: 'Mobile App',
      description: 'React Native application',
      ownerId: user2.id,
    },
  });

  console.log('✅ Created projects:', project1.id, project2.id);

  // Create sample tasks
  const task1 = await prisma.task.create({
    data: {
      title: 'Setup monorepo',
      description: 'Initialize Turborepo project structure',
      status: 'COMPLETED',
      projectId: project1.id,
    },
  });

  const task2 = await prisma.task.create({
    data: {
      title: 'Create API endpoints',
      description: 'Build REST API with NestJS',
      status: 'IN_PROGRESS',
      projectId: project1.id,
    },
  });

  console.log('✅ Created tasks:', task1.id, task2.id);

  // Create sample comments
  const comment1 = await prisma.comment.create({
    data: {
      content: 'Great progress on the setup!',
      taskId: task1.id,
      authorId: user1.id,
    },
  });

  console.log('✅ Created comment:', comment1.id);

  console.log('✅ Seeding complete!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
