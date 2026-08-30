const getDateRange = (period, startDate) => {
  const start = new Date(startDate || Date.now());
  const end = new Date(start);

  switch (period) {
    case 'weekly':
      end.setDate(start.getDate() + 7);
      break;
    case 'monthly':
      end.setMonth(start.getMonth() + 1);
      break;
    case 'quarterly':
      end.setMonth(start.getMonth() + 3);
      break;
    case 'yearly':
      end.setFullYear(start.getFullYear() + 1);
      break;
    default:
      end.setMonth(start.getMonth() + 1);
  }

  return { start, end };
};

const getCurrentPeriodRange = (period) => {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);

  switch (period) {
    case 'weekly': {
      const dayOfWeek = now.getDay();
      start.setDate(now.getDate() - dayOfWeek);
      break;
    }
    case 'monthly':
      start.setDate(1);
      break;
    case 'quarterly':
      start.setMonth(Math.floor(now.getMonth() / 3) * 3, 1);
      break;
    case 'yearly':
      start.setMonth(0, 1);
      break;
  }

  const { end } = getDateRange(period, start);
  return { start, end };
};

module.exports = { getDateRange, getCurrentPeriodRange };
