import React from 'react';
import { Clock, CheckCircle2 } from 'lucide-react';
import { useTasks } from '../hooks/useTasks';
import { formatDate } from '../utils/date';

export function TasksList() {
  const { data: tasks, isLoading, error } = useTasks();

  if (isLoading) return <div>Loading tasks...</div>;
  if (error) return <div>Error loading tasks</div>;

  return (
    <div className="space-y-4">
      {tasks?.map((task) => (
        <div key={task.id} className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {task.status === 'completed' ? (
                <CheckCircle2 className="h-5 w-5 text-green-500" />
              ) : (
                <Clock className="h-5 w-5 text-yellow-500" />
              )}
              <div>
                <p className="font-medium">{task.details}</p>
                <p className="text-sm text-gray-500">
                  Due: {formatDate(task.due_date)}
                </p>
              </div>
            </div>
            <span className={`px-2 py-1 rounded-full text-xs ${
              task.status === 'completed' 
                ? 'bg-green-100 text-green-800'
                : 'bg-yellow-100 text-yellow-800'
            }`}>
              {task.status}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}