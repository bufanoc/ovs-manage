import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Paper,
  Typography,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { Add as AddIcon } from '@mui/icons-material';
import { toast } from 'react-toastify';
import api from '../services/api';

function LogicalSwitches() {
  const [switches, setSwitches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [newSwitch, setNewSwitch] = useState({ name: '', description: '' });

  const columns = [
    { field: 'name', headerName: 'Name', flex: 1 },
    { field: 'uuid', headerName: 'UUID', flex: 1 },
    { field: 'ports', headerName: 'Ports', flex: 1, valueGetter: (params) => params.row.ports?.length || 0 },
    {
      field: 'actions',
      headerName: 'Actions',
      flex: 1,
      renderCell: (params) => (
        <Button
          variant="outlined"
          color="error"
          size="small"
          onClick={() => handleDelete(params.row.uuid)}
        >
          Delete
        </Button>
      ),
    },
  ];

  useEffect(() => {
    fetchSwitches();
  }, []);

  const fetchSwitches = async () => {
    try {
      const response = await api.get('/logical-switches');
      setSwitches(response.data);
    } catch (error) {
      toast.error('Failed to fetch logical switches');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async () => {
    try {
      await api.post('/logical-switches', newSwitch);
      toast.success('Logical switch created successfully');
      setOpenDialog(false);
      setNewSwitch({ name: '', description: '' });
      fetchSwitches();
    } catch (error) {
      toast.error('Failed to create logical switch');
    }
  };

  const handleDelete = async (uuid) => {
    try {
      await api.delete(`/logical-switches/${uuid}`);
      toast.success('Logical switch deleted successfully');
      fetchSwitches();
    } catch (error) {
      toast.error('Failed to delete logical switch');
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h5">Logical Switches</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setOpenDialog(true)}
        >
          Create Switch
        </Button>
      </Box>

      <Paper sx={{ height: 400, width: '100%' }}>
        <DataGrid
          rows={switches}
          columns={columns}
          pageSize={5}
          rowsPerPageOptions={[5]}
          checkboxSelection
          disableSelectionOnClick
          loading={loading}
          getRowId={(row) => row.uuid}
        />
      </Paper>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)}>
        <DialogTitle>Create Logical Switch</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Name"
            fullWidth
            value={newSwitch.name}
            onChange={(e) => setNewSwitch({ ...newSwitch, name: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Description"
            fullWidth
            value={newSwitch.description}
            onChange={(e) => setNewSwitch({ ...newSwitch, description: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button onClick={handleCreate} variant="contained">Create</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default LogicalSwitches;
