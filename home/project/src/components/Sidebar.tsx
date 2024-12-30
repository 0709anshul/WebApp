import React from 'react';
import { 
  LayoutDashboard, 
  ClipboardList, 
  Package2, 
  Users, 
  Building2
} from 'lucide-react';

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', href: '/' },
  { icon: ClipboardList, label: 'Production Orders', href: '/orders' },
  { icon: Package2, label: 'Products', href: '/products' },
  { icon: Users, label: 'Users', href: '/users' },
  { icon: Building2, label: 'Customer Brands', href: '/brands' },
];

export default function Sidebar() {
  return (
    <div className="w-64 bg-indigo-800 text-white">
      <div className="p-4">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Layout className="h-6 w-6" />
          Leumasware®
        </h1>
      </div>
      <nav className="mt-8">
        {menuItems.map((item) => (
          <a
            key={item.label}
            href={item.href}
            className="flex items-center gap-2 px-4 py-2 hover:bg-indigo-700"
          >
            <item.icon className="h-5 w-5" />
            {item.label}
          </a>
        ))}
      </nav>
    </div>
  );
}