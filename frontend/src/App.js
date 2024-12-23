import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

// Layout components
import Layout from './components/Layout';

// Pages
import Dashboard from './pages/Dashboard';
import LogicalSwitches from './pages/LogicalSwitches';
import LogicalRouters from './pages/LogicalRouters';
import LoadBalancers from './pages/LoadBalancers';
import ACLs from './pages/ACLs';
import Settings from './pages/Settings';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#0a1929',
      paper: '#132f4c',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h5: {
      fontWeight: 500,
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
        },
      },
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/logical-switches" element={<LogicalSwitches />} />
            <Route path="/logical-routers" element={<LogicalRouters />} />
            <Route path="/load-balancers" element={<LoadBalancers />} />
            <Route path="/acls" element={<ACLs />} />
            <Route path="/settings" element={<Settings />} />
          </Routes>
        </Layout>
      </Router>
      <ToastContainer position="bottom-right" />
    </ThemeProvider>
  );
}

export default App;
