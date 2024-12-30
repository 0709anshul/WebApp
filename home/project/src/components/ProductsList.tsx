import React from 'react';
import { useProducts } from '../hooks/useProducts';

export function ProductsList() {
  const { data: products, isLoading, error } = useProducts();

  if (isLoading) return <div>Loading products...</div>;
  if (error) return <div>Error loading products</div>;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {products?.map((product) => (
        <div key={product.id} className="bg-white rounded-lg shadow p-4">
          <div className="flex justify-between items-start">
            <div>
              <h3 className="font-medium">{product.name}</h3>
              <p className="text-sm text-gray-500">Batch size: {product.batch_size}</p>
            </div>
            <p className="text-indigo-600 font-medium">₹{product.price_inr}</p>
          </div>
        </div>
      ))}
    </div>
  );
}