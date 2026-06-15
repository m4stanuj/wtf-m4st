/* ═══════════════════════════════════════════════════════════
   M4ST Command Center — Configuration
   Service registry, crew registry, API config
   ═══════════════════════════════════════════════════════════ */

// API Configuration
export const API_BASE = import.meta.env.VITE_API_BASE || '';
export const API_TOKEN = import.meta.env.VITE_API_TOKEN || 'default_secret_token';

// Polling intervals
export const HEALTH_INTERVAL = 10_000;  // 10s
export const RAM_INTERVAL = 30_000;     // 30s

// Service Registry — all 9 M4ST services
export const SERVICES = [
  {
    id: 'openclaw',
    key: 'openclaw',
    name: 'OpenClaw',
    port: 3001,
    url: 'http://localhost:3001',
    layer: 'core',
    ram: 500,
    icon: '🐾',
    description: 'Core runtime, Telegram/WhatsApp gateway'
  },
  {
    id: 'ninerouter',
    key: 'ninerouter',
    name: '9Router',
    port: 20128,
    url: 'http://localhost:20128/dashboard',
    layer: 'core',
    ram: 200,
    icon: '🔀',
    description: 'LLM routing, MITM intercept, 56 API keys'
  },
  {
    id: 'openwork-mcp',
    key: 'openwork-mcp',
    name: 'OpenWork MCP',
    port: 8765,
    url: null,
    layer: 'core',
    ram: 200,
    icon: '🔌',
    description: 'IDE bridge — tools + memory + dashboard'
  },
  {
    id: 'sepcc',
    key: 'sepcc',
    name: 'SEPCC',
    port: 8082,
    url: null,
    layer: 'proxy',
    ram: 50,
    icon: '🦊',
    description: 'Claude Code session proxy'
  },
  {
    id: 'graphiti-mcp',
    key: 'graphiti-mcp',
    name: 'Graphiti MCP',
    port: 8001,
    url: 'http://localhost:8001/sse',
    layer: 'memory',
    ram: 400,
    icon: '🧠',
    description: 'Temporal memory (SSE)'
  },
  {
    id: 'falkordb',
    key: 'falkordb',
    name: 'FalkorDB',
    port: 6379,
    url: null,
    layer: 'memory',
    ram: 1000,
    icon: '🗄️',
    description: 'Graph database for Graphiti'
  },
  {
    id: 'cognee-mcp',
    key: 'cognee-mcp',
    name: 'Cognee MCP',
    port: 8000,
    url: null,
    layer: 'memory',
    ram: 500,
    icon: '📚',
    description: 'Project knowledge graph'
  },
  {
    id: 'langfuse',
    key: 'langfuse',
    name: 'Langfuse',
    port: 3000,
    url: 'http://localhost:3000',
    layer: 'observe',
    ram: 600,
    icon: '📊',
    description: 'LLM observability + tracing'
  },
  {
    id: 'uptime-kuma',
    key: 'uptime-kuma',
    name: 'Uptime Kuma',
    port: 3002,
    url: 'http://localhost:3002',
    layer: 'observe',
    ram: 200,
    icon: '🟢',
    description: 'Service health + Telegram alerts'
  }
];

// Crew Registry — 3 crews, 11 agents total
export const CREWS = [
  {
    id: 'nightly',
    name: 'Nightly Crew',
    file: 'nightly_crew',
    icon: '🌙',
    color: '#a855f7',
    colorGlow: 'rgba(168, 85, 247, 0.15)',
    schedule: '11:00 PM',
    agents: [
      { role: 'Scanner', llm: 'fast' },
      { role: 'Drafter', llm: 'fast' },
      { role: 'Fixer', llm: 'deep' },
      { role: 'Reporter', llm: 'fast' }
    ],
    description: 'GitHub scan, content draft, auto-fix, Telegram report'
  },
  {
    id: 'content',
    name: 'Content Crew',
    file: 'content_crew',
    icon: '✍️',
    color: '#3b82f6',
    colorGlow: 'rgba(59, 130, 246, 0.15)',
    schedule: '1:00 AM',
    agents: [
      { role: 'Researcher', llm: 'fast' },
      { role: 'Writer', llm: 'fast' },
      { role: 'Reviewer', llm: 'fast' }
    ],
    description: 'AI trend research, social content, honesty review'
  },
  {
    id: 'bugfix',
    name: 'Bugfix Crew',
    file: 'bugfix_crew',
    icon: '🔧',
    color: '#00ff41',
    colorGlow: 'rgba(0, 255, 65, 0.15)',
    schedule: '3:00 AM',
    agents: [
      { role: 'Analyzer', llm: 'deep' },
      { role: 'Fixer', llm: 'deep' },
      { role: 'Tester', llm: 'fast' }
    ],
    description: 'Root cause analysis, patching, test verification'
  }
];

// Architecture layers for diagram
export const ARCH_LAYERS = [
  {
    label: 'ENTRY',
    icon: '🚪',
    nodes: ['Telegram', 'WhatsApp', 'Antigravity IDE', 'Cursor', 'Windsurf']
  },
  {
    label: 'CORE',
    icon: '🧠',
    nodes: ['OpenClaw :3001', '9Router :20128', 'SEPCC :8082', 'OpenWork MCP :8765']
  },
  {
    label: 'MEMORY',
    icon: '💾',
    nodes: ['Graphiti MCP :8001', 'FalkorDB :6379', 'Cognee MCP :8000']
  },
  {
    label: 'OBSERVE',
    icon: '📊',
    nodes: ['Langfuse :3000', 'Uptime Kuma :3002']
  },
  {
    label: 'SWARM',
    icon: '🤖',
    nodes: ['Nightly Crew', 'Content Crew', 'Bugfix Crew', 'CrewAI v1.14']
  }
];

// Layer color map
export const LAYER_COLORS = {
  core: '#00ff41',
  memory: '#a855f7',
  observe: '#3b82f6',
  proxy: '#ffb830'
};
