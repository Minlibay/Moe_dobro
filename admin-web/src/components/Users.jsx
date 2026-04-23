import { useState, useEffect } from 'react';
import { getUsers, verifyUser, blockUser } from '../services/api';
import { CheckCircle, XCircle, Search, Ban, Unlock } from 'lucide-react';

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      const data = await getUsers({ search, limit: 100 });
      setUsers(data.users);
    } catch (error) {
      console.error('Error loading users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (userId, isVerified) => {
    try {
      await verifyUser(userId, !isVerified);
      loadUsers();
    } catch (error) {
      console.error('Error verifying user:', error);
    }
  };

  const handleBlock = async (userId, isBlocked) => {
    const reason = isBlocked
      ? null
      : prompt('Укажите причину блокировки:');

    if (!isBlocked && !reason) return;

    try {
      await blockUser(userId, !isBlocked, reason);
      loadUsers();
    } catch (error) {
      console.error('Error blocking user:', error);
      alert('Ошибка при блокировке пользователя');
    }
  };

  const handleSearch = () => {
    loadUsers();
  };

  if (loading) return <div className="p-6">Загрузка...</div>;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Пользователи</h1>

      {/* Поиск */}
      <div className="mb-6 flex gap-2">
        <input
          type="text"
          placeholder="Поиск по имени или телефону..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          style={{
            flex: 1,
            padding: '12px 16px',
            border: '2px solid #e2e8f0',
            borderRadius: '12px',
            fontSize: '14px',
            outline: 'none',
            transition: 'all 0.3s'
          }}
        />
        <button
          onClick={handleSearch}
          style={{
            padding: '12px 24px',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            border: 'none',
            borderRadius: '12px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontWeight: 600,
            fontSize: '14px',
            boxShadow: '0 4px 12px rgba(102, 126, 234, 0.3)',
            transition: 'all 0.3s'
          }}
        >
          <Search className="w-5 h-5" />
          Поиск
        </button>
      </div>

      {/* Таблица */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Имя</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Телефон</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Донатов</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Получено</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Статус</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действия</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id}>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{user.id}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">{user.full_name}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{user.phone}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{user.total_donated} ₽</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{user.total_received} ₽</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {user.is_blocked ? (
                    <span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded-full">Заблокирован</span>
                  ) : user.is_verified ? (
                    <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full">Верифицирован</span>
                  ) : (
                    <span className="px-2 py-1 text-xs bg-gray-100 text-gray-800 rounded-full">Не верифицирован</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={() => handleVerify(user.id, user.is_verified)}
                      disabled={user.is_blocked}
                      style={{
                        padding: '8px 16px',
                        background: user.is_verified
                          ? 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)'
                          : 'linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%)',
                        color: user.is_verified ? '#991b1b' : '#065f46',
                        border: 'none',
                        borderRadius: '8px',
                        cursor: user.is_blocked ? 'not-allowed' : 'pointer',
                        fontWeight: 600,
                        fontSize: '13px',
                        transition: 'all 0.3s',
                        boxShadow: user.is_verified
                          ? '0 2px 8px rgba(239, 68, 68, 0.2)'
                          : '0 2px 8px rgba(16, 185, 129, 0.2)',
                        opacity: user.is_blocked ? 0.5 : 1
                      }}
                    >
                      {user.is_verified ? 'Снять' : 'Верифицировать'}
                    </button>
                    <button
                      onClick={() => handleBlock(user.id, user.is_blocked)}
                      style={{
                        padding: '8px 16px',
                        background: user.is_blocked
                          ? 'linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%)'
                          : 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)',
                        color: user.is_blocked ? '#1e40af' : '#991b1b',
                        border: 'none',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        fontWeight: 600,
                        fontSize: '13px',
                        transition: 'all 0.3s',
                        boxShadow: user.is_blocked
                          ? '0 2px 8px rgba(59, 130, 246, 0.2)'
                          : '0 2px 8px rgba(239, 68, 68, 0.2)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px'
                      }}
                    >
                      {user.is_blocked ? (
                        <>
                          <Unlock className="w-4 h-4" />
                          Разблокировать
                        </>
                      ) : (
                        <>
                          <Ban className="w-4 h-4" />
                          Заблокировать
                        </>
                      )}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
