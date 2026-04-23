import { useState, useEffect } from 'react';
import { getStats } from '../services/api';
import { Users, Heart, DollarSign, TrendingUp, CheckCircle, Clock } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const data = await getStats();
      setStats(data);
    } catch (error) {
      console.error('Error loading stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-screen">Загрузка...</div>;
  }

  if (!stats) {
    return <div className="flex items-center justify-center h-screen">Ошибка загрузки данных</div>;
  }

  const { overview, daily_stats, top_categories } = stats;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Панель управления</h1>

      {/* Статистика карточки */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <StatCard
          icon={<Users className="w-8 h-8" />}
          title="Пользователи"
          value={overview.total_users}
          subtitle={`${overview.verified_users} верифицированы`}
          color="linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
        />
        <StatCard
          icon={<Heart className="w-8 h-8" />}
          title="Сборы"
          value={overview.total_fundraisers}
          subtitle={`${overview.active_fundraisers} активных`}
          color="linear-gradient(135deg, #f093fb 0%, #f5576c 100%)"
        />
        <StatCard
          icon={<DollarSign className="w-8 h-8" />}
          title="Донаты"
          value={overview.total_donations}
          subtitle={`${overview.pending_donations} ожидают`}
          color="linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)"
        />
        <StatCard
          icon={<TrendingUp className="w-8 h-8" />}
          title="Всего собрано"
          value={`${parseFloat(overview.total_amount).toLocaleString('ru-RU')} ₽`}
          subtitle={`Средний: ${parseFloat(overview.avg_donation).toFixed(0)} ₽`}
          color="linear-gradient(135deg, #fa709a 0%, #fee140 100%)"
        />
        <StatCard
          icon={<CheckCircle className="w-8 h-8" />}
          title="Одобрено"
          value={overview.approved_donations}
          subtitle="донатов"
          color="linear-gradient(135deg, #30cfd0 0%, #330867 100%)"
        />
        <StatCard
          icon={<Clock className="w-8 h-8" />}
          title="Ожидают"
          value={overview.pending_donations}
          subtitle="донатов"
          color="linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)"
        />
      </div>

      {/* Графики */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* График донатов по дням */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-bold mb-4">Донаты за последние 30 дней</h2>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={daily_stats}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="donations_count" stroke="#8884d8" name="Количество" />
              <Line type="monotone" dataKey="total_amount" stroke="#82ca9d" name="Сумма" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Топ категорий */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-bold mb-4">Популярные категории</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={top_categories}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={(entry) => entry.category}
                outerRadius={80}
                fill="#8884d8"
                dataKey="count"
              >
                {top_categories.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Таблица категорий */}
      <div className="bg-white p-6 rounded-lg shadow">
        <h2 className="text-xl font-bold mb-4">Статистика по категориям</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Категория</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Сборов</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Собрано</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {top_categories.map((cat, index) => (
                <tr key={index}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="text-sm font-medium text-gray-900">{getCategoryName(cat.category)}</span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{cat.count}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {parseFloat(cat.total_raised || 0).toLocaleString('ru-RU')} ₽
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon, title, value, subtitle, color }) {
  return (
    <div className="bg-white p-6 rounded-lg shadow" style={{ position: 'relative', overflow: 'hidden' }}>
      <div style={{
        position: 'absolute',
        top: -20,
        right: -20,
        width: 100,
        height: 100,
        background: color,
        opacity: 0.1,
        borderRadius: '50%'
      }} />
      <div className="flex items-center" style={{ position: 'relative', zIndex: 1 }}>
        <div style={{
          background: color,
          padding: '14px',
          borderRadius: '14px',
          marginRight: '16px',
          boxShadow: `0 4px 14px ${color}40`
        }}>
          <div style={{ color: 'white' }}>{icon}</div>
        </div>
        <div>
          <p style={{ color: '#64748b', fontSize: '13px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{title}</p>
          <p style={{ fontSize: '28px', fontWeight: 800, color: '#1e293b', marginTop: '4px' }}>{value}</p>
          <p style={{ color: '#94a3b8', fontSize: '12px', marginTop: '2px' }}>{subtitle}</p>
        </div>
      </div>
    </div>
  );
}

function getCategoryName(category) {
  const names = {
    mortgage: 'Ипотека',
    medical: 'Лечение',
    education: 'Образование',
    other: 'Другое',
  };
  return names[category] || category;
}
