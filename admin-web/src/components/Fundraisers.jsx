import { useState, useEffect } from 'react';
import { getFundraisers, closeFundraiser, featureFundraiser, deleteFundraiser, verifyCompletion } from '../services/api';
import { Search, MoreVertical, Lock, Star, Trash2, CheckCircle, Eye } from 'lucide-react';

export default function Fundraisers() {
  const [fundraisers, setFundraisers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [openMenu, setOpenMenu] = useState(null);
  const [showProofModal, setShowProofModal] = useState(false);
  const [selectedFundraiser, setSelectedFundraiser] = useState(null);

  useEffect(() => {
    loadFundraisers();
  }, []);

  const loadFundraisers = async () => {
    try {
      const params = {};
      if (search) params.search = search;
      if (status) params.status = status;
      if (category) params.category = category;
      params.limit = 100;

      const data = await getFundraisers(params);
      setFundraisers(data.fundraisers);
    } catch (error) {
      console.error('Error loading fundraisers:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = async (id) => {
    if (!confirm('Закрыть этот сбор?')) return;
    try {
      await closeFundraiser(id);
      loadFundraisers();
      setOpenMenu(null);
    } catch (error) {
      console.error('Error closing fundraiser:', error);
      alert('Ошибка при закрытии сбора');
    }
  };

  const handleFeature = async (id, isFeatured) => {
    try {
      await featureFundraiser(id, !isFeatured);
      loadFundraisers();
      setOpenMenu(null);
    } catch (error) {
      console.error('Error featuring fundraiser:', error);
      alert('Ошибка при изменении статуса избранного');
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Удалить этот сбор? Это действие нельзя отменить!')) return;
    try {
      await deleteFundraiser(id);
      loadFundraisers();
      setOpenMenu(null);
    } catch (error) {
      console.error('Error deleting fundraiser:', error);
      alert(error.response?.data?.error || 'Ошибка при удалении сбора');
    }
  };

  const handleSearch = () => {
    loadFundraisers();
  };

  const handleVerifyCompletion = async (fundraiserId) => {
    if (!confirm('Подтвердить успешное завершение этого сбора?')) return;
    try {
      await verifyCompletion(fundraiserId);
      loadFundraisers();
      setShowProofModal(false);
    } catch (error) {
      console.error('Error verifying completion:', error);
      alert('Ошибка при подтверждении завершения');
    }
  };

  const openProofModal = (fundraiser) => {
    setSelectedFundraiser(fundraiser);
    setShowProofModal(true);
  };

  const closeProofModal = () => {
    setShowProofModal(false);
    setSelectedFundraiser(null);
  };

  if (loading) return <div className="p-6">Загрузка...</div>;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Сборы</h1>

      {/* Фильтры */}
      <div className="mb-6 flex gap-2 flex-wrap">
        <input
          type="text"
          placeholder="Поиск по названию..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          style={{
            flex: '1 1 200px',
            minWidth: '200px',
            padding: '12px 16px',
            border: '2px solid #e2e8f0',
            borderRadius: '12px',
            fontSize: '14px',
            outline: 'none',
            transition: 'all 0.3s'
          }}
        />
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          style={{
            padding: '12px 16px',
            border: '2px solid #e2e8f0',
            borderRadius: '12px',
            fontSize: '14px',
            outline: 'none',
            cursor: 'pointer',
            backgroundColor: 'white',
            transition: 'all 0.3s'
          }}
        >
          <option value="">Все статусы</option>
          <option value="active">Активные</option>
          <option value="completed">Завершенные</option>
          <option value="closed">Закрытые</option>
        </select>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          style={{
            padding: '12px 16px',
            border: '2px solid #e2e8f0',
            borderRadius: '12px',
            fontSize: '14px',
            outline: 'none',
            cursor: 'pointer',
            backgroundColor: 'white',
            transition: 'all 0.3s'
          }}
        >
          <option value="">Все категории</option>
          <option value="mortgage">Ипотека</option>
          <option value="medical">Лечение</option>
          <option value="education">Образование</option>
          <option value="other">Другое</option>
        </select>
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
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Название</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Категория</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Цель</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Собрано</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Статус</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Завершение</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действия</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {fundraisers.map((fundraiser) => (
              <tr key={fundraiser.id}>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{fundraiser.id}</td>
                <td className="px-6 py-4 text-sm font-medium">
                  <div className="flex items-center gap-2">
                    {fundraiser.title}
                    {fundraiser.is_featured && <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{getCategoryName(fundraiser.category)}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{parseFloat(fundraiser.goal_amount).toLocaleString('ru-RU')} ₽</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{parseFloat(fundraiser.current_amount).toLocaleString('ru-RU')} ₽</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {fundraiser.status === 'active' && (
                    <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full">Активный</span>
                  )}
                  {fundraiser.status === 'completed' && (
                    <span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">Завершен</span>
                  )}
                  {fundraiser.status === 'closed' && (
                    <span className="px-2 py-1 text-xs bg-gray-100 text-gray-800 rounded-full">Закрыт</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {fundraiser.completion_verified ? (
                    <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full flex items-center gap-1 w-fit">
                      <CheckCircle className="w-3 h-3" />
                      Подтверждено
                    </span>
                  ) : fundraiser.completion_submitted_at ? (
                    <button
                      onClick={() => openProofModal(fundraiser)}
                      className="px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full flex items-center gap-1 hover:bg-yellow-200 transition-colors"
                    >
                      <Eye className="w-3 h-3" />
                      Проверить
                    </button>
                  ) : (
                    <span className="text-gray-400 text-xs">Не отправлено</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm relative">
                  <button
                    onClick={() => setOpenMenu(openMenu === fundraiser.id ? null : fundraiser.id)}
                    style={{
                      padding: '8px',
                      background: 'transparent',
                      border: '2px solid #e2e8f0',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      transition: 'all 0.3s',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.background = '#f1f5f9'}
                    onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                  >
                    <MoreVertical className="w-5 h-5" style={{ color: '#64748b' }} />
                  </button>
                  {openMenu === fundraiser.id && (
                    <div style={{
                      position: 'absolute',
                      right: 0,
                      marginTop: '8px',
                      width: '220px',
                      background: 'white',
                      borderRadius: '12px',
                      boxShadow: '0 10px 40px rgba(0, 0, 0, 0.15)',
                      border: '1px solid #e2e8f0',
                      zIndex: 10,
                      overflow: 'hidden'
                    }}>
                      {fundraiser.status === 'active' && (
                        <button
                          onClick={() => handleClose(fundraiser.id)}
                          style={{
                            width: '100%',
                            padding: '12px 16px',
                            textAlign: 'left',
                            background: 'transparent',
                            border: 'none',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '10px',
                            fontSize: '14px',
                            fontWeight: 500,
                            color: '#334155',
                            transition: 'all 0.2s'
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.background = '#f8fafc'}
                          onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                        >
                          <Lock className="w-4 h-4" />
                          Закрыть
                        </button>
                      )}
                      <button
                        onClick={() => handleFeature(fundraiser.id, fundraiser.is_featured)}
                        style={{
                          width: '100%',
                          padding: '12px 16px',
                          textAlign: 'left',
                          background: 'transparent',
                          border: 'none',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '10px',
                          fontSize: '14px',
                          fontWeight: 500,
                          color: '#334155',
                          transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.background = '#f8fafc'}
                        onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                      >
                        <Star className="w-4 h-4" />
                        {fundraiser.is_featured ? 'Убрать из избранного' : 'Добавить в избранное'}
                      </button>
                      <button
                        onClick={() => handleDelete(fundraiser.id)}
                        style={{
                          width: '100%',
                          padding: '12px 16px',
                          textAlign: 'left',
                          background: 'transparent',
                          border: 'none',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '10px',
                          fontSize: '14px',
                          fontWeight: 500,
                          color: '#dc2626',
                          transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.background = '#fef2f2'}
                        onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                      >
                        <Trash2 className="w-4 h-4" />
                        Удалить
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Модальное окно для просмотра подтверждения завершения */}
      {showProofModal && selectedFundraiser && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '20px'
          }}
          onClick={closeProofModal}
        >
          <div
            style={{
              background: 'white',
              borderRadius: '16px',
              maxWidth: '800px',
              width: '100%',
              maxHeight: '90vh',
              overflow: 'auto',
              boxShadow: '0 20px 60px rgba(0, 0, 0, 0.3)'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{
              padding: '24px',
              borderBottom: '1px solid #e2e8f0'
            }}>
              <h2 style={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '8px' }}>
                Подтверждение завершения сбора
              </h2>
              <p style={{ color: '#64748b', fontSize: '14px' }}>
                {selectedFundraiser.title}
              </p>
            </div>

            <div style={{ padding: '24px' }}>
              {/* Информация о сборе */}
              <div style={{
                background: '#f8fafc',
                padding: '16px',
                borderRadius: '12px',
                marginBottom: '20px'
              }}>
                <p style={{ marginBottom: '8px' }}>
                  <strong>Создатель:</strong> {selectedFundraiser.creator_name} ({selectedFundraiser.creator_phone})
                </p>
                <p style={{ marginBottom: '8px' }}>
                  <strong>Цель:</strong> {parseFloat(selectedFundraiser.goal_amount).toLocaleString('ru-RU')} ₽
                </p>
                <p style={{ marginBottom: '8px' }}>
                  <strong>Собрано:</strong> {parseFloat(selectedFundraiser.current_amount).toLocaleString('ru-RU')} ₽
                </p>
                <p>
                  <strong>Отправлено:</strong> {new Date(selectedFundraiser.completion_submitted_at).toLocaleString('ru-RU')}
                </p>
              </div>

              {/* Сообщение */}
              {selectedFundraiser.completion_message && (
                <div style={{ marginBottom: '20px' }}>
                  <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '8px' }}>
                    Сообщение от создателя:
                  </h3>
                  <p style={{
                    background: '#f8fafc',
                    padding: '12px',
                    borderRadius: '8px',
                    color: '#334155',
                    lineHeight: '1.6'
                  }}>
                    {selectedFundraiser.completion_message}
                  </p>
                </div>
              )}

              {/* Подтверждающий документ */}
              {selectedFundraiser.completion_proof_url && (
                <div style={{ marginBottom: '20px' }}>
                  <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '8px' }}>
                    Подтверждающий документ:
                  </h3>
                  <img
                    src={`http://127.0.0.1:3003${selectedFundraiser.completion_proof_url}`}
                    alt="Подтверждение"
                    style={{
                      width: '100%',
                      borderRadius: '12px',
                      border: '2px solid #e2e8f0'
                    }}
                  />
                </div>
              )}

              {/* Кнопки действий */}
              <div style={{
                display: 'flex',
                gap: '12px',
                justifyContent: 'flex-end',
                marginTop: '24px'
              }}>
                <button
                  onClick={closeProofModal}
                  style={{
                    padding: '12px 24px',
                    background: '#f1f5f9',
                    color: '#334155',
                    border: 'none',
                    borderRadius: '12px',
                    cursor: 'pointer',
                    fontWeight: 600,
                    fontSize: '14px',
                    transition: 'all 0.3s'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.background = '#e2e8f0'}
                  onMouseLeave={(e) => e.currentTarget.style.background = '#f1f5f9'}
                >
                  Закрыть
                </button>
                {!selectedFundraiser.completion_verified && (
                  <button
                    onClick={() => handleVerifyCompletion(selectedFundraiser.id)}
                    style={{
                      padding: '12px 24px',
                      background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                      color: 'white',
                      border: 'none',
                      borderRadius: '12px',
                      cursor: 'pointer',
                      fontWeight: 600,
                      fontSize: '14px',
                      boxShadow: '0 4px 12px rgba(16, 185, 129, 0.3)',
                      transition: 'all 0.3s',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
                    onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
                  >
                    <CheckCircle className="w-5 h-5" />
                    Подтвердить завершение
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
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
