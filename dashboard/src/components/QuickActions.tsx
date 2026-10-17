import { CalendarDays, Plus, Sparkles } from 'lucide-react';

import { Button } from './ui';

interface QuickActionsProps {
  onBook: () => void;
  onChat: () => void;
  onSchedule: () => void;
}

export function QuickActions({ onBook, onChat, onSchedule }: QuickActionsProps) {
  return (
    <div className="grid gap-3 sm:grid-cols-3">
      <Button variant="primary" className="h-12 w-full" onClick={onBook}>
        <Plus className="h-4 w-4" />
        Book New Service
      </Button>
      <Button variant="secondary" className="h-12 w-full" onClick={onChat}>
        <Sparkles className="h-4 w-4" />
        AI Assistant Chat
      </Button>
      <Button variant="outline" className="h-12 w-full" onClick={onSchedule}>
        <CalendarDays className="h-4 w-4" />
        View Schedule
      </Button>
    </div>
  );
}
