import { useState, useEffect } from 'react';
import { getDonations, approveDonation, rejectDonation } from '../services/api';
import { Search, CheckCircle, Clock, XCircle, Eye, Check, X } from 'lucide-react';

export default function Donations() {
  const [donations, setDonations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('');
  const [selectedDonation, setSelectedDonation] = useState(null);
  const [showImageModal, setShowImageModal] = useState(false);

  useEffect(() => {
    loadDonations();
  }, []);

  const loadDonations = async () => {
    try {
      const params = { limit: 100 };
      if (status) params.status = status;

      const data = await getDonations(params);
      console.log('Loaded donations:', data.donations);
      setDonations(data.donations);
    } catch (error) {
      console.error('Error loading donations:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (newStatus) => {
    setStatus(newStatus);
  };

  useEffect(() => {
    loadDonations();
  }, [status]);

  const handleApprove = async (donationId) => {
    if (!confirm('Подтвердить этот донат?')) return;
    try {
      await approveDonation(donationId);
      loadDonations();
    } catch (error) {
      console.error('Error approving donation:', error);
      alert('Ошибка при подтверждении доната');
    }
  };

  const handleReject = async (donationId) => {
    const reason = prompt('Укажите причину отклонения:');
    if (!reason) return;

    try {
      await rejectDonation(donationId, reason);
      loadDonations();
    } catch (error) {
      console.error('Error rejecting donation:', error);
      alert('Ошибка при отклонении доната');
    }
  };

  const openImageModal = (donation) => {
    setSelectedDonation(donation);
    setShowImageModal(true);
  };

  const closeImageModal = () => {
    setShowImageModal(false);
    setSelectedDonation(null);
  };

  const isPending24Hours = (createdAt) => {
    const created = new Date(createdAt);
    const now = new Date();
    const diffHours = (now - created) / (1000 * 60 * 60);
    return diffHours >= 24;
  };

  if (loading) return <div className="p-6">Загрузка...</div>;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Донаты</h1>

      {/* Фильтры */}
      <div className="mb-6 flex gap-2">
        <select
          value={status}
          onChange={(e) => handleFilterChange(e.target.value)}
          style={{
            padding: '12px 16px',
            border: '2px solid #e2e8f0',
            borderRadius: '12px',
            fontSize: '14px',
            outline: 'none',
            cursor: 'pointer',
            backgroundColor: 'white',
            transition: 'all 0.3s',
            fontWeight: 500
          }}
        >
          <option value="">Все статусы</option>
          <option value="pending">Ожидают</option>
          <option value="approved">Одобрены</option>
          <option value="rejected">Отклонены</option>
        </select>
      </div>

      {/* Таблица */}
      <div className="bg-white rounded-lg shadow overflow-x-auto">
        <table className="min-w-full" style={{ minWidth: '1200px' }}>
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">От кого</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Кому</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Сбор</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Сумма</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Скриншот</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Статус</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Дата</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действия</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {donations.map((donation) => {
              console.log('Rendering donation:', donation.id, 'screenshot:', donation.screenshot_url);
              return (
              <tr key={donation.id} style={{
                backgroundColor: donation.status === 'pending' && isPending24Hours(donation.created_at)
                  ? '#fef3c7'
                  : 'transparent'
              }}>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{donation.id}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  <div>
                    <div className="font-medium">{donation.donor_name || 'Аноним'}</div>
                    <div className="text-gray-500 text-xs">{donation.donor_phone}</div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {donation.recipient_name}
                </td>
                <td className="px-6 py-4 text-sm max-w-xs truncate">
                  {donation.fundraiser_title}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  {parseFloat(donation.amount).toLocaleString('ru-RU')} ₽
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {donation.screenshot_url ? (
                    <button
                      onClick={() => openImageModal(donation)}
                      style={{
                        padding: '6px 12px',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        fontSize: '13px',
                        fontWeight: 600,
                        boxShadow: '0 2px 8px rgba(102, 126, 234, 0.3)'
                      }}
                    >
                      <Eye className="w-4 h-4" />
                      Просмотр
                    </button>
                  ) : (
                    <span style={{ color: '#94a3b8', fontSize: '13px' }}>Нет скриншота</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {donation.status === 'approved' && (
                    <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full flex items-center gap-1 w-fit">
                      <CheckCircle className="w-3 h-3" />
                      Одобрен
                    </span>
                  )}
                  {donation.status === 'pending' && (
                    <span className="px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full flex items-center gap-1 w-fit">
                      <Clock className="w-3 h-3" />
                      Ожидает
                    </span>
                  )}
                  {donation.status === 'rejected' && (
                    <span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded-full flex items-center gap-1 w-fit">
                      <XCircle className="w-3 h-3" />
                      Отклонен
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {new Date(donation.created_at).toLocaleDateString('ru-RU')}
                  <div className="text-xs text-gray-400">
                    {new Date(donation.created_at).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {donation.status === 'pending' && (
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        onClick={() => handleApprove(donation.id)}
                        style={{
                          padding: '8px 12px',
                          background: 'linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%)',
                          color: '#065f46',
                          border: 'none',
                          borderRadius: '8px',
                          cursor: 'pointer',
                          fontWeight: 600,
                          fontSize: '13px',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px'
                        }}
                      >
                        <Check className="w-4 h-4" />
                        Одобрить
                      </button>
                      <button
                        onClick={() => handleReject(donation.id)}
                        style={{
                          padding: '8px 12px',
                          background: 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)',
                          color: '#991b1b',
                          border: 'none',
                          borderRadius: '8px',
                          cursor: 'pointer',
                          fontWeight: 600,
                          fontSize: '13px',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px'
                        }}
                      >
                        <X className="w-4 h-4" />
                        Отклонить
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            );
            })}
          </tbody>
        </table>
      </div>

      {donations.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          Донаты не найдены
        </div>
      )}

      {/* Модальное окно для просмотра скриншота */}
      {showImageModal && selectedDonation && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '20px'
          }}
          onClick={closeImageModal}
        >
          <div
            style={{
              backgroundColor: 'white',
              borderRadius: '16px',
              padding: '24px',
              maxWidth: '800px',
              maxHeight: '90vh',
              overflow: 'auto'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ marginBottom: '16px' }}>
              <h3 style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '8px' }}>
                Скриншот перевода
              </h3>
              <div style={{ fontSize: '14px', color: '#64748b', marginBottom: '16px' }}>
                <p><strong>От:</strong> {selectedDonation.donor_name} ({selectedDonation.donor_phone})</p>
                <p><strong>Кому:</strong> {selectedDonation.recipient_name} ({selectedDonation.recipient_phone})</p>
                <p><strong>Сумма:</strong> {parseFloat(selectedDonation.amount).toLocaleString('ru-RU')} ₽</p>
                <p><strong>Сбор:</strong> {selectedDonation.fundraiser_title}</p>
              </div>

              {/* Реквизиты получателя */}
              <div style={{
                padding: '16px',
                background: 'linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%)',
                borderRadius: '12px',
                border: '2px solid #bae6fd',
                marginBottom: '16px'
              }}>
                <h4 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '8px', color: '#0c4a6e' }}>
                  📋 Реквизиты для перевода
                </h4>
                <div style={{ fontSize: '14px', color: '#0c4a6e' }}>
                  {selectedDonation.payment_method === 'sbp' && selectedDonation.sbp_phone && (
                    <>
                      <p><strong>Способ оплаты:</strong> СБП (Система быстрых платежей)</p>
                      <p><strong>Номер телефона:</strong> <span style={{
                        fontFamily: 'monospace',
                        fontSize: '16px',
                        fontWeight: 'bold',
                        background: 'white',
                        padding: '4px 8px',
                        borderRadius: '6px'
                      }}>{selectedDonation.sbp_phone}</span></p>
                      {selectedDonation.sbp_bank && (
                        <p><strong>Банк:</strong> {selectedDonation.sbp_bank}</p>
                      )}
                      <p style={{ fontSize: '12px', color: '#0369a1', marginTop: '8px' }}>
                        💡 Донор должен был перевести деньги через СБП на этот номер
                      </p>
                    </>
                  )}
                  {selectedDonation.payment_method === 'card' && selectedDonation.card_number && (
                    <>
                      <p><strong>Способ оплаты:</strong> Банковская карта</p>
                      <p><strong>Номер карты:</strong> <span style={{
                        fontFamily: 'monospace',
                        fontSize: '16px',
                        fontWeight: 'bold',
                        background: 'white',
                        padding: '4px 8px',
                        borderRadius: '6px'
                      }}>{selectedDonation.card_number}</span></p>
                      {selectedDonation.card_holder_name && (
                        <p><strong>Владелец карты:</strong> {selectedDonation.card_holder_name}</p>
                      )}
                      {selectedDonation.bank_name && (
                        <p><strong>Банк:</strong> {selectedDonation.bank_name}</p>
                      )}
                      <p style={{ fontSize: '12px', color: '#0369a1', marginTop: '8px' }}>
                        💡 Донор должен был перевести деньги на эту карту
                      </p>
                    </>
                  )}
                  {(!selectedDonation.payment_method || (!selectedDonation.sbp_phone && !selectedDonation.card_number)) && (
                    <p style={{ color: '#64748b' }}>Реквизиты не указаны</p>
                  )}
                </div>
              </div>
            </div>
            <img
              src={`http://127.0.0.1:3003${selectedDonation.screenshot_url}`}
              alt="Скриншот перевода"
              style={{
                width: '100%',
                height: 'auto',
                borderRadius: '12px',
                marginBottom: '16px'
              }}
              onError={(e) => {
                console.error('Failed to load image:', selectedDonation.screenshot_url);
                e.target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300"><rect width="400" height="300" fill="%23f3f4f6"/><text x="50%" y="50%" text-anchor="middle" fill="%2364748b" font-size="16">Не удалось загрузить изображение</text></svg>';
              }}
            />
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              {selectedDonation.status === 'pending' && (
                <>
                  <button
                    onClick={() => {
                      handleApprove(selectedDonation.id);
                      closeImageModal();
                    }}
                    style={{
                      padding: '10px 20px',
                      background: 'linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%)',
                      color: '#065f46',
                      border: 'none',
                      borderRadius: '10px',
                      cursor: 'pointer',
                      fontWeight: 600,
                      fontSize: '14px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px'
                    }}
                  >
                    <Check className="w-5 h-5" />
                    Одобрить
                  </button>
                  <button
                    onClick={() => {
                      handleReject(selectedDonation.id);
                      closeImageModal();
                    }}
                    style={{
                      padding: '10px 20px',
                      background: 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)',
                      color: '#991b1b',
                      border: 'none',
                      borderRadius: '10px',
                      cursor: 'pointer',
                      fontWeight: 600,
                      fontSize: '14px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px'
                    }}
                  >
                    <X className="w-5 h-5" />
                    Отклонить
                  </button>
                </>
              )}
              <button
                onClick={closeImageModal}
                style={{
                  padding: '10px 20px',
                  background: '#e2e8f0',
                  color: '#334155',
                  border: 'none',
                  borderRadius: '10px',
                  cursor: 'pointer',
                  fontWeight: 600,
                  fontSize: '14px'
                }}
              >
                Закрыть
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
