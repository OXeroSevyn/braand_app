export type UserRole = 'Admin' | 'Employee';
export type UserStatus = 'pending' | 'active' | 'rejected';

export interface UserProfile {
    id: string;
    name: string;
    email: string;
    role: UserRole;
    department: string;
    avatar?: string;
    bio?: string;
    phone?: string;
    status: UserStatus;
}
