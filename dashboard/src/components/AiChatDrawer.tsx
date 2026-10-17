import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Bot, Send, Sparkles } from 'lucide-react';

import { Drawer } from './ui';

interface Message {
  id: number;
  role: 'user' | 'assistant';
  text: string;
}

const GREETING =
  "Hi Abdul! I'm your BookEase assistant. I can help you book a service, " +
  "reschedule an appointment, or check what's coming up next.";

const SUGGESTIONS = [
  'What’s my next appointment?',
  'Book a haircut for Saturday',
  'Can I move my massage?',
];

const draftReply = (prompt: string): string => {
  const text = prompt.toLowerCase();
  if (text.includes('cancel')) {
    return 'No problem — open the appointment in the list and tap Cancel, and I’ll free the slot instantly. Want me to cancel the massage on Friday instead?';
  }
  if (text.includes('reschedul') || text.includes('move') || text.includes('change')) {
    return 'I can move that. Which day suits you better — Saturday morning or Sunday afternoon? I’ll hold the slot for you.';
  }
  if (text.includes('book') || text.includes('new') || text.includes('appointment')) {
    return 'Great — tap “Book New Service” and pick a service and slot, or tell me the service and I’ll draft the booking for you.';
  }
  if (text.includes('next') || text.includes('upcoming') || text.includes('when')) {
    return 'Your next appointment is the Dental Checkup today at 3:30 PM with Dr. Ayesha Khan. Should I send a reminder 30 minutes before?';
  }
  if (text.includes('price') || text.includes('cost') || text.includes('pay')) {
    return 'Pricing depends on the service — consultations start at $35. Your last 9 bookings totalled $1,010 across 9 services.';
  }
  if (text.includes('hi') || text.includes('hello') || text.includes('hey')) {
    return 'Hey! How can I help with your bookings today?';
  }
  return 'Got it. I’ve noted that — is there a specific service or date you’d like me to look at?';
};

export function AiChatDrawer({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [draft, setDraft] = useState('');
  const [typing, setTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  // Seed the conversation the first time the drawer opens.
  useEffect(() => {
    if (!open || messages.length > 0) return;
    setMessages([{ id: 1, role: 'assistant', text: GREETING }]);
  }, [open, messages.length]);

  // Keep the latest message in view.
  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: 'smooth',
    });
  }, [messages, typing]);

  const send = (raw: string) => {
    const text = raw.trim();
    if (!text) return;
    const id = Date.now();
    setMessages((current) => [...current, { id, role: 'user', text }]);
    setDraft('');
    setTyping(true);

    window.setTimeout(() => {
      setMessages((current) => [
        ...current,
        { id: id + 1, role: 'assistant', text: draftReply(text) },
      ]);
      setTyping(false);
    }, 620);
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    send(draft);
  };

  return (
    <Drawer
      open={open}
      onClose={onClose}
      title="AI Assistant"
      subtitle="BookEase smart assistant · online"
      headerIcon={
        <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-linear-to-br from-indigo-600 to-violet-600 text-white">
          <Bot className="h-4 w-4" />
        </span>
      }
      footer={
        <form onSubmit={handleSubmit} className="flex items-center gap-2">
          <label className="sr-only" htmlFor="chat-input">
            Message the assistant
          </label>
          <input
            id="chat-input"
            className="min-w-0 flex-1 rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-sm transition placeholder:text-slate-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
            placeholder="Ask about your bookings…"
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            autoComplete="off"
          />
          <button
            type="submit"
            aria-label="Send message"
            disabled={!draft.trim()}
            className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-indigo-600 text-white transition hover:bg-indigo-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40 disabled:cursor-not-allowed disabled:opacity-40"
          >
            <Send className="h-4 w-4" />
          </button>
        </form>
      }
    >
      <div
        ref={scrollRef}
        className="h-full space-y-4 overflow-y-auto bg-slate-50/60 px-5 py-5"
      >
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${
              message.role === 'user' ? 'justify-end' : 'justify-start'
            }`}
          >
            <div
              className={`max-w-[85%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed shadow-sm ${
                message.role === 'user'
                  ? 'rounded-br-md bg-indigo-600 text-white'
                  : 'rounded-bl-md border border-slate-200 bg-white text-slate-700'
              }`}
            >
              {message.text}
            </div>
          </div>
        ))}

        {typing ? (
          <div className="flex justify-start">
            <div className="flex items-center gap-1.5 rounded-2xl rounded-bl-md border border-slate-200 bg-white px-4 py-3 shadow-sm">
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-slate-400 [animation-delay:-0.2s]" />
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-slate-400 [animation-delay:-0.1s]" />
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-slate-400" />
            </div>
          </div>
        ) : null}

        {messages.length <= 1 && !typing ? (
          <div className="space-y-2 pt-2">
            <p className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-slate-400">
              <Sparkles className="h-3.5 w-3.5" />
              Try asking
            </p>
            {SUGGESTIONS.map((suggestion) => (
              <button
                key={suggestion}
                type="button"
                onClick={() => send(suggestion)}
                className="block w-full rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-left text-sm text-slate-600 shadow-sm transition hover:border-indigo-200 hover:bg-indigo-50/50 hover:text-indigo-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40"
              >
                {suggestion}
              </button>
            ))}
          </div>
        ) : null}
      </div>
    </Drawer>
  );
}
