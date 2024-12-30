import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Database } from '../lib/database.types';

type Product = Database['public']['Tables']['products']['Row'];

export function useProducts() {
  const [data, setData] = useState<Product[] | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    async function fetchProducts() {
      try {
        const { data, error } = await supabase
          .from('products')
          .select('*')
          .order('name');

        if (error) throw error;
        setData(data);
      } catch (e) {
        setError(e instanceof Error ? e : new Error('Error loading products'));
      } finally {
        setIsLoading(false);
      }
    }

    fetchProducts();
  }, []);

  return { data, isLoading, error };
}