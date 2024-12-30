import React from 'react';
import { ClipboardList, Package2, Building2, Clock } from 'lucide-react';
import { DashboardLayout } from './components/DashboardLayout';
import { StatCard } from './components/StatCard';
import { ProductsList } from './components/ProductsList';
import { TasksList } from './components/TasksList';

export default function App() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            icon={ClipboardList}
            label="Active Orders"
            value={1}
            color="bg-blue-500"
          />
          <StatCard
            icon={Clock}
            label="Pending Tasks"
            value={12}
            color="bg-yellow-500"
          />
          <StatCard
            icon={Package2}
            label="Total Products"
            value={12}
            color="bg-green-500"
          />
          <StatCard
            icon={Building2}
            label="Active Brands"
            value={5}
            color="bg-purple-500"
          />
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Products Section */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-lg font-semibold mb-4">Products</h2>
            <ProductsList />
          </div>

          {/* Tasks Section */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-lg font-semibold mb-4">Recent Tasks</h2>
            <TasksList />
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}