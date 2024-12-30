import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Database } from '../lib/database.types';

type Task = Database['public']['Tables']['tasks']['Row'];

export function useTasks() {
  const [data, setData] = useState<Task[] | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    async function fetchTasks() {
      try {
        const { data, error } = await supabase
          .from('tasks')
          .select('*')
          .order('created_at', { ascending: false });

        if (error) throw error;
        setData(data);
      } catch (e) {
        setError(e instanceof Error ? e : new Error('Error loading tasks'));
      } finally {
        setIsLoading(false);
      }
    }

    fetchTasks();
  }, []);

  return { data, isLoading, error };
}