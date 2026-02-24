import { supabase } from './supabase';
import { UserProfile } from '@/types/user';

export const profileService = {
    async getProfile(id: string): Promise<UserProfile | null> {
        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', id)
            .single();

        if (error) return null;
        return data as UserProfile;
    },
};

export interface Task {
    id: string;
    user_id: string;
    title: string;
    description?: string;
    is_completed: boolean;
    task_date: string;
    priority: string;
}

export const taskService = {
    async getUserTasks(userId: string, date: Date = new Date()): Promise<Task[]> {
        const start = new Date(date);
        start.setHours(0, 0, 0, 0);
        const end = new Date(date);
        end.setHours(23, 59, 59, 999);

        const { data, error } = await supabase
            .from('tasks')
            .select('*')
            .eq('user_id', userId)
            .gte('task_date', start.toISOString())
            .lte('task_date', end.toISOString())
            .order('created_at', { ascending: true });

        if (error) {
            console.error('Error fetching tasks:', error.message);
            return [];
        }
        return data as Task[];
    },

    async toggleTask(taskId: string, isCompleted: boolean) {
        const { error } = await supabase
            .from('tasks')
            .update({ is_completed: isCompleted })
            .eq('id', taskId);

        if (error) throw error;
    }
};
