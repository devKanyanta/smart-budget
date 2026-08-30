const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const sequelize = require('../src/config/database');
const {
  User, AdminUser, Category, Transaction, Budget,
  SavingsGoal, SavingsEntry, MobileMoneyAccount, Notification, FinancialInsight,
} = require('../src/models');
const { DEFAULT_CATEGORIES } = require('../src/config/constants');

const RESET = process.argv.includes('--reset');

// ─── Sample Data ───────────────────────────────────────────

const USERS = [
  {
    email: 'khadijah@example.com',
    full_name: 'Khadijah Zimba',
    phone_number: '+260971234567',
    password: 'password123',
  },
  {
    email: 'james@example.com',
    full_name: 'James Phiri',
    phone_number: '+260961234567',
    password: 'password123',
  },
  {
    email: 'grace@example.com',
    full_name: 'Grace Mwamba',
    phone_number: '+260951234567',
    password: 'password123',
  },
  {
    email: 'admin@smartbudgetzm.com',
    full_name: 'System Admin',
    phone_number: '+260991234567',
    password: 'admin123',
    isAdmin: true,
  },
];

const ZAMBIAN_TRANSACTIONS = {
  income: [
    { desc: 'Monthly salary', min: 5000, max: 25000 },
    { desc: 'Airtel Money top-up from savings', min: 200, max: 2000 },
    { desc: 'MTN MoMo received from client', min: 500, max: 5000 },
    { desc: 'Freelance payment', min: 500, max: 8000 },
    { desc: 'Market sales revenue', min: 100, max: 3000 },
    { desc: 'Part-time tutoring income', min: 300, max: 1500 },
    { desc: 'Family support transfer', min: 500, max: 5000 },
  ],
  expense: [
    { desc: 'Shoprite grocery shopping', category: 'Food', min: 100, max: 1500 },
    { desc: 'Market produce purchase', category: 'Food', min: 50, max: 500 },
    { desc: 'Lunch at KFC Lusaka', category: 'Food', min: 45, max: 150 },
    { desc: 'Minibus fare to work', category: 'Transport', min: 5, max: 30 },
    { desc: 'Taxi ride home', category: 'Transport', min: 20, max: 100 },
    { desc: 'Fuel for car', category: 'Transport', min: 200, max: 800 },
    { desc: 'ZESCO electricity bill', category: 'Utilities', min: 150, max: 800 },
    { desc: 'Water bill - Lusaka Water', category: 'Utilities', min: 50, max: 200 },
    { desc: 'DStv subscription', category: 'Utilities', min: 150, max: 300 },
    { desc: 'Movie night at EastPark', category: 'Entertainment', min: 50, max: 200 },
    { desc: 'Netflix subscription', category: 'Entertainment', min: 80, max: 150 },
    { desc: 'Game night drinks', category: 'Entertainment', min: 100, max: 400 },
    { desc: 'Clothing purchase at Manda Hill', category: 'Shopping', min: 200, max: 2000 },
    { desc: 'Phone accessories', category: 'Shopping', min: 50, max: 500 },
    { desc: 'School fees payment', category: 'Education', min: 500, max: 5000 },
    { desc: 'Online course subscription', category: 'Education', min: 100, max: 500 },
    { desc: 'Clinic visit fee', category: 'Healthcare', min: 100, max: 500 },
    { desc: 'Pharmacy medication', category: 'Healthcare', min: 50, max: 300 },
    { desc: 'Rent payment', category: 'Housing', min: 1500, max: 5000 },
    { desc: 'Home repairs', category: 'Housing', min: 100, max: 1000 },
    { desc: 'Airtel airtime purchase', category: 'Communication', min: 10, max: 100 },
    { desc: 'MTN data bundle', category: 'Communication', min: 20, max: 200 },
    { desc: 'Internet subscription', category: 'Communication', min: 100, max: 500 },
    { desc: 'Tigo Pesa transfer fee', category: 'Other', min: 5, max: 50 },
  ],
};

// ─── Helpers ───────────────────────────────────────────────

function randomBetween(min, max) {
  return Math.round((Math.random() * (max - min) + min) * 100) / 100;
}

function randomDate(startDate, endDate) {
  const start = new Date(startDate).getTime();
  const end = new Date(endDate).getTime();
  return new Date(start + Math.random() * (end - start));
}

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// ─── Seed Function ────────────────────────────────────────

async function seed() {
  try {
    console.log('🔌 Connecting to database...');
    await sequelize.authenticate();
    console.log('✅ Connected');

    if (RESET) {
      console.log('🗑️  Resetting database...');
      await sequelize.sync({ force: true });
      console.log('✅ Database reset');
    } else {
      await sequelize.sync({ alter: true });
    }

    // ── Categories ──
    console.log('📂 Seeding categories...');
    const categories = {};
    for (const cat of DEFAULT_CATEGORIES) {
      const [instance] = await Category.findOrCreate({
        where: { name: cat.name },
        defaults: { ...cat, is_system: true },
      });
      categories[cat.name] = instance;
    }
    console.log(`  → ${Object.keys(categories).length} categories`);

    // ── Users ──
    console.log('👤 Seeding users...');
    const users = [];
    for (const userData of USERS) {
      const [user] = await User.findOrCreate({
        where: { email: userData.email },
        defaults: {
          full_name: userData.full_name,
          phone_number: userData.phone_number,
          password_hash: await bcrypt.hash(userData.password, 12),
          status: 'active',
        },
      });
      users.push(user);

      if (userData.isAdmin) {
        await AdminUser.findOrCreate({
          where: { user_id: user.id },
          defaults: { role: 'super_admin' },
        });
      }
    }
    console.log(`  → ${users.length} users created`);

    // ── Transactions (6 months of data per user) ──
    console.log('💰 Seeding transactions...');
    const now = new Date();
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 6, 1);

    for (const user of users) {
      if (user.email === 'admin@smartbudgetzm.com') continue; // Skip admin for transactions

      const transactionCount = 0;

      for (let month = 0; month < 6; month++) {
        const monthStart = new Date(now.getFullYear(), now.getMonth() - month, 1);
        const monthEnd = new Date(now.getFullYear(), now.getMonth() - month + 1, 0);

        // 1-2 income transactions per month
        const incomeCount = Math.floor(Math.random() * 2) + 1;
        for (let i = 0; i < incomeCount; i++) {
          const template = pickRandom(ZAMBIAN_TRANSACTIONS.income);
          const incomeCategory = categories['Income'];
          await Transaction.create({
            user_id: user.id,
            amount: randomBetween(template.min, template.max),
            type: 'income',
            description: template.desc,
            category_id: incomeCategory?.id,
            category_source: 'auto',
            source: pickRandom(['airtel_money', 'mtn_momo', 'manual']),
            transaction_date: randomDate(monthStart, monthEnd),
          });
        }

        // 15-30 expense transactions per month
        const expenseCount = Math.floor(Math.random() * 16) + 15;
        for (let i = 0; i < expenseCount; i++) {
          const template = pickRandom(ZAMBIAN_TRANSACTIONS.expense);
          const category = categories[template.category] || categories['Other'];
          await Transaction.create({
            user_id: user.id,
            amount: randomBetween(template.min, template.max),
            type: 'expense',
            description: template.desc,
            category_id: category?.id,
            category_source: Math.random() > 0.3 ? 'auto' : 'manual',
            source: pickRandom(['airtel_money', 'mtn_momo', 'manual']),
            transaction_date: randomDate(monthStart, monthEnd),
          });
        }
      }
      console.log(`  → User ${user.full_name}: transactions seeded`);
    }

    // ── Budgets ──
    console.log('📊 Seeding budgets...');
    const budgetTemplates = [
      { categoryName: 'Food', amount: 2000, period: 'monthly' },
      { categoryName: 'Transport', amount: 800, period: 'monthly' },
      { categoryName: 'Utilities', amount: 1000, period: 'monthly' },
      { categoryName: 'Entertainment', amount: 500, period: 'monthly' },
      { categoryName: 'Shopping', amount: 1000, period: 'monthly' },
      { categoryName: null, amount: 8000, period: 'monthly' }, // Overall budget
    ];

    for (const user of users) {
      if (user.email === 'admin@smartbudgetzm.com') continue;
      for (const bt of budgetTemplates) {
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        await Budget.findOrCreate({
          where: {
            user_id: user.id,
            category_id: categories[bt.categoryName]?.id || null,
            period: bt.period,
          },
          defaults: {
            amount: bt.amount,
            start_date: monthStart.toISOString().split('T')[0],
            alert_threshold: 80,
            is_active: true,
          },
        });
      }
    }
    console.log('  → Budgets seeded');

    // ── Savings Goals ──
    console.log('🏦 Seeding savings goals...');
    const savingsTemplates = [
      { name: 'Emergency Fund', target: 10000, frequency: 'monthly' },
      { name: 'Vacation to Victoria Falls', target: 5000, frequency: 'weekly' },
      { name: 'New Laptop Fund', target: 8000, frequency: 'monthly' },
    ];

    for (const user of users) {
      if (user.email === 'admin@smartbudgetzm.com') continue;
      for (const st of savingsTemplates) {
        const [goal] = await SavingsGoal.findOrCreate({
          where: { user_id: user.id, name: st.name },
          defaults: {
            target_amount: st.target,
            target_date: new Date(now.getFullYear(), now.getMonth() + 6, 1).toISOString().split('T')[0],
            frequency: st.frequency,
            status: 'active',
          },
        });

        // Add 3-8 savings entries
        const entryCount = Math.floor(Math.random() * 6) + 3;
        let currentAmount = 0;
        for (let i = 0; i < entryCount; i++) {
          const amount = randomBetween(100, 1000);
          currentAmount += amount;
          await SavingsEntry.create({
            savings_goal_id: goal.id,
            amount,
            entry_date: randomDate(sixMonthsAgo, now),
          });
        }
        goal.current_amount = currentAmount;
        if (currentAmount >= parseFloat(goal.target_amount)) goal.status = 'completed';
        await goal.save();
      }
    }
    console.log('  → Savings goals seeded');

    // ── Mobile Money Accounts ──
    console.log('📱 Seeding mobile money accounts...');
    const mmUsers = users.filter((u) => u.email !== 'admin@smartbudgetzm.com');
    for (const user of mmUsers) {
      await MobileMoneyAccount.findOrCreate({
        where: { user_id: user.id, provider: 'airtel_money' },
        defaults: {
          phone_number: user.phone_number,
          display_name: `Airtel Money - ${user.phone_number}`,
          sync_status: 'synced',
          last_synced_at: new Date(),
        },
      });
      if (Math.random() > 0.5) {
        await MobileMoneyAccount.findOrCreate({
          where: { user_id: user.id, provider: 'mtn_momo' },
          defaults: {
            phone_number: user.phone_number,
            display_name: `MTN MoMo - ${user.phone_number}`,
            sync_status: 'synced',
            last_synced_at: new Date(),
          },
        });
      }
    }
    console.log('  → Mobile money accounts seeded');

    // ── Notifications ──
    console.log('🔔 Seeding notifications...');
    for (const user of users) {
      if (user.email === 'admin@smartbudgetzm.com') continue;
      const notifTemplates = [
        { type: 'budget_alert', title: 'Budget Alert', body: "You've used 85% of your Food budget this month." },
        { type: 'savings_reminder', title: 'Savings Reminder', body: "Don't forget to add to your Emergency Fund this week!" },
        { type: 'insight', title: 'Weekly Insight', body: 'Your spending on Transport increased by 15% this week.' },
        { type: 'sync_status', title: 'Sync Complete', body: '12 new transactions synced from Airtel Money.' },
        { type: 'general', title: 'Welcome to Smart Budget ZM!', body: 'Start tracking your finances today. Set up budgets and savings goals.' },
      ];
      for (const nt of notifTemplates) {
        await Notification.create({
          user_id: user.id,
          ...nt,
          is_read: Math.random() > 0.5,
        });
      }
    }
    console.log('  → Notifications seeded');

    // ── Financial Insights ──
    console.log('💡 Seeding financial insights...');
    for (const user of users) {
      if (user.email === 'admin@smartbudgetzm.com') continue;
      const insightTemplates = [
        { insight_type: 'spending_tip', title: 'High Food Spending', body: 'Your food expenses are above average this month. Consider cooking more at home to save.', priority: 'medium' },
        { insight_type: 'savings_tip', title: 'Savings Goal on Track', body: "Great job! You're on track to meet your Emergency Fund goal by the target date.", priority: 'low' },
        { insight_type: 'budget_tip', title: 'Budget Review', body: 'You have 20% of your transport budget remaining with 10 days left in the month.', priority: 'medium' },
        { insight_type: 'trend_alert', title: 'Spending Trend', body: 'Your overall spending has decreased by 8% compared to last month. Keep it up!', priority: 'low' },
        { insight_type: 'category_insight', title: 'Top Category', body: 'Food is your highest spending category, making up 35% of your total expenses.', priority: 'medium' },
      ];
      for (const it of insightTemplates) {
        await FinancialInsight.create({
          user_id: user.id,
          ...it,
          is_read: Math.random() > 0.5,
        });
      }
    }
    console.log('  → Financial insights seeded');

    console.log('\n🎉 Seeding complete!');
    console.log('\n📋 Login credentials:');
    console.log('  User:    khadijah@example.com / password123');
    console.log('  User:    james@example.com / password123');
    console.log('  User:    grace@example.com / password123');
    console.log('  Admin:   admin@smartbudgetzm.com / admin123');

    process.exit(0);
  } catch (error) {
    console.error('❌ Seed error:', error);
    process.exit(1);
  }
}

seed();
