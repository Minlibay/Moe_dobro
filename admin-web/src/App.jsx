import { BrowserRouter, Routes, Route, Navigate, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, Heart, DollarSign, LogOut } from 'lucide-react';
import Dashboard from './components/Dashboard';
import UsersComponent from './components/Users';
import Fundraisers from './components/Fundraisers';
import Donations from './components/Donations';
import Login from './components/Login';
import { logout } from './services/api';
import './App.css';

function Sidebar() {
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  const handleLogout = () => {
    logout();
  };

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <h2>Моё добро</h2>
        <p>Админ-панель</p>
      </div>

      <nav className="sidebar-nav">
        <Link to="/" className={isActive('/') ? 'active' : ''}>
          <LayoutDashboard className="w-5 h-5" />
          <span>Панель</span>
        </Link>
        <Link to="/users" className={isActive('/users') ? 'active' : ''}>
          <Users className="w-5 h-5" />
          <span>Пользователи</span>
        </Link>
        <Link to="/fundraisers" className={isActive('/fundraisers') ? 'active' : ''}>
          <Heart className="w-5 h-5" />
          <span>Сборы</span>
        </Link>
        <Link to="/donations" className={isActive('/donations') ? 'active' : ''}>
          <DollarSign className="w-5 h-5" />
          <span>Донаты</span>
        </Link>
      </nav>

      <button onClick={handleLogout} className="logout-btn">
        <LogOut className="w-5 h-5" />
        <span>Выйти</span>
      </button>
    </div>
  );
}

function ProtectedRoute({ children }) {
  const token = localStorage.getItem('admin_token');
  return token ? children : <Navigate to="/login" />;
}

function AppLayout({ children }) {
  return (
    <div className="app-layout">
      <Sidebar />
      <main className="main-content">{children}</main>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <AppLayout>
                <Dashboard />
              </AppLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/users"
          element={
            <ProtectedRoute>
              <AppLayout>
                <UsersComponent />
              </AppLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/fundraisers"
          element={
            <ProtectedRoute>
              <AppLayout>
                <Fundraisers />
              </AppLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donations"
          element={
            <ProtectedRoute>
              <AppLayout>
                <Donations />
              </AppLayout>
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
