// Projects sidebar: live open workspaces on top, your projects below.
// Clicking a project row opens a new workspace named after it, in its folder.
//
// Customize: edit GROUPS below. cmux hot-reloads this file on save.
// Open:   cmux sidebar open projects    (pane)
// Select: cmux sidebar select projects  (left sidebar)

const HOME = "__HOME__/";

// One section per group. Each project: [name, folder relative to HOME, GitHub repo name if it differs].
// The dot color marks the group.
const GROUPS = [
  {
    title: "PROJECTS",
    color: "#3b82f6",
    projects: [
      // ["my-app", "code/my-app"],
      // ["website", "code/website", "my-website-repo"],
    ],
  },
  {
    title: "PERSONAL",
    color: "#a855f7",
    projects: [
      // ["dotfiles", ".dotfiles", ".dotfiles"],
    ],
  },
].map((g) => ({
  ...g,
  repos: g.projects.map(([name, path, gh]) => ({ name, gh, color: g.color, cwd: HOME + path })),
}));
const REPOS = GROUPS.flatMap((g) => g.repos);

// Open-PR count per GitHub repo name, filled by ~/.config/cmux/pr-counts.sh <owner>
// (sidebars can't make network calls themselves).
const PR_COUNTS = {};

const ws = () => data.workspaces() ?? [];
const inRepo = (w, r) => {
  const d = (w.directory ?? "").toLowerCase(), c = r.cwd.toLowerCase();
  return d === c || d.startsWith(c + "/");
};
const repoOf = (w) => REPOS.find((r) => inRepo(w, r));
const openFor = (r) => ws().find((w) => inRepo(w, r));

// Ignore repeat clicks on the same row for 5s so one click = one workspace.
const [pending, setPending] = signal({});
const isPending = (r) => (data.clock()?.epoch ?? 0) - (pending()[r.name] ?? -1e9) < 5;

// Every click opens a fresh workspace named after the repo, in its folder.
function launch(r) {
  if (isPending(r)) return;
  setPending({ ...pending(), [r.name]: data.clock()?.epoch ?? 0 });
  cmux("workspace.create", { title: r.name, cwd: r.cwd, focus: true });
}

const STATES = {
  needs_input: { glyph: "◆", color: "#f59e0b", label: "needs input" },
  working: { glyph: "●", color: "#10b981", label: "working" },
  idle: { glyph: "○", color: "secondary", label: "idle" },
  ended: { glyph: "·", color: "tertiary", label: "ended" },
  none: { glyph: "", color: "clear", label: "" },
};

// Claude reports "idle" when it finishes a turn; the "waiting for your input"
// part only arrives as an unread notification on its terminal.
function statusOf(w, a) {
  if (a.status !== "idle") return a.status;
  const tab = (w.tabs ?? []).find((t) => t.id === a.panelId);
  return tab?.hasUnread || (!a.panelId && w.unread > 0) ? "needs_input" : "idle";
}

// Workspace pill: the most urgent agent state wins (waiting on you > working > idle).
function agentState(w) {
  const agents = (w.agents ?? []).filter((a) => a.status !== "ended");
  if (w.status === "needs-attention" || agents.some((a) => statusOf(w, a) === "needs_input")) return STATES.needs_input;
  if (agents.some((a) => a.status === "working")) return STATES.working;
  if (agents.length) return STATES.idle;
  return STATES.none;
}

function ago(epoch) {
  if (!epoch) return "";
  const s = Math.max(0, (data.clock()?.epoch ?? epoch) - epoch);
  return s < 60 ? `${Math.floor(s)}s` : s < 3600 ? `${Math.floor(s / 60)}m` : `${Math.floor(s / 3600)}h`;
}

// One line per live agent session; tap jumps to its terminal.
const agentRow = (w, a) =>
  HStack({ spacing: 6 }, [
    Text(() => (STATES[statusOf(w(), a())] ?? STATES.idle).glyph)
      .font("caption")
      .color(() => (STATES[statusOf(w(), a())] ?? STATES.idle).color),
    Text(() => a().title ?? (w().tabs ?? []).find((t) => t.id === a().panelId)?.latestPrompt ?? a().name ?? a().kind)
      .font("caption")
      .lineLimit(1),
    Spacer(),
    Text(() => `${(STATES[statusOf(w(), a())] ?? STATES.idle).label} ${ago(a().sinceEpoch ?? a().lastActivityAt)}`)
      .font("caption")
      .monospaced()
      .color(() => (STATES[statusOf(w(), a())] ?? STATES.idle).color)
      .fixedSize(),
  ])
    .paddingVertical(2)
    .paddingHorizontal(6)
    .hoverBackground("#80808014")
    .cornerRadius(4)
    .cursor("pointer")
    .onTap(() =>
      a().surfaceId
        ? cmux("surface.focus", { surface_id: a().surfaceId, workspace_id: w().id })
        : cmux("workspace.select", { workspace_id: w().id }));

const header = (title, count) =>
  HStack({ spacing: 6 }, [
    Text(title).font("caption").bold().secondary(),
    Spacer(),
    Text(count).font("caption").monospaced().secondary(),
  ]).paddingHorizontal(6);

const openRow = (w) =>
  VStack({ spacing: 1, alignment: "leading" }, [
  HStack({ spacing: 8 }, [
    RoundedRectangle({ cornerRadius: 2 })
      .fill(() => w().color ?? repoOf(w())?.color ?? "secondary")
      .frame({ width: 3, height: 32 }),
    // Title gets the full first line; status details share the second.
    VStack({ spacing: 2, alignment: "leading" }, [
      HStack({ spacing: 6 }, [
        Text(() => w().title).lineLimit(1).weight(() => (w().selected ? "semibold" : "regular")).frame({ maxWidth: 9999, alignment: "leading" }),
        Text(() => (w().unread > 0 ? String(w().unread) : ""))
          .font("caption")
          .bold()
          .color("#ef4444")
          .fixedSize(),
      ]),
      HStack({ spacing: 6 }, [
        Text(() => (w().branch ? `${w().branch}${w().dirty ? " •" : ""}` : ""))
          .font("caption")
          .monospaced()
          .secondary()
          .lineLimit(1),
        Spacer(),
        Text(() => (w().pr ? `#${w().pr.number}` : ""))
          .font("caption")
          .monospaced()
          .color(() => (w().pr?.status === "merged" ? "#8b5cf6" : w().pr?.status === "closed" ? "secondary" : "#10b981"))
          .fixedSize(),
        Text(() => agentState(w()).label)
          .font("caption")
          .bold()
          .color(() => agentState(w()).color)
          .paddingHorizontal(() => (agentState(w()).label ? 6 : 0))
          .paddingVertical(1)
          .background(() => (agentState(w()).label ? "#80808020" : null))
          .cornerRadius(8)
          .fixedSize(),
      ]),
    ]),
  ])
    .padding(6)
    .background(() => (w().selected ? "#3b82f61f" : null))
    .hoverBackground("#80808014")
    .cornerRadius(6)
    .cursor("pointer")
    .onTap(() => cmux("workspace.select", { workspace_id: w().id }))
    .contextMenu([
      Button(() => (w().pinned ? "Unpin" : "Pin"), () =>
        cmux("workspace.action", { action: w().pinned ? "unpin" : "pin", workspace_id: w().id })),
      Divider(),
      Button("Close", () => cmux("workspace.close", { workspace_id: w().id })).destructive(),
    ]),
    VStack({ spacing: 0 }, [
      ForEach(
        { items: () => (w().agents ?? []).filter((a) => a.status !== "ended").slice(0, 6), key: (a) => a.id },
        (a) => agentRow(w, a)
      ),
    ]).padding({ leading: 14 }),
  ]);

const repoRow = (r) =>
  HStack({ spacing: 8 }, [
    Circle({ size: 7 }).fill(r.color),
    Text(r.name).lineLimit(1).opacity(() => (openFor(r) ? 1 : 0.75)),
    Text(PR_COUNTS[r.gh ?? r.name] ? String(PR_COUNTS[r.gh ?? r.name]) : "")
      .font("caption")
      .monospaced()
      .bold()
      .color("#10b981")
      .paddingHorizontal(PR_COUNTS[r.gh ?? r.name] ? 5 : 0)
      .background(PR_COUNTS[r.gh ?? r.name] ? "#10b98122" : null)
      .cornerRadius(8)
      .fixedSize(),
    Spacer(),
    Text(() => (openFor(r) ? "open" : isPending(r) ? "…" : ""))
      .font("caption")
      .secondary(),
  ])
    .paddingVertical(2)
    .paddingHorizontal(5)
    .hoverBackground("#80808014")
    .cornerRadius(6)
    .cursor("pointer")
    .onTap(() => launch(r));

sidebar(() =>
  VStack({ spacing: 6 }, [
    HStack([
      Text("Projects").font("headline"),
      Spacer(),
      Text(() => (data.unreadTotal() > 0 ? `${data.unreadTotal()} unread` : "")).font("caption").secondary(),
    ]).paddingHorizontal(6),
    Divider(),
    header("OPEN", () => String(ws().length)),
    Reorderable(
      {
        items: () => ws().slice(0, 30),
        key: (w) => w.id,
        onMove: (id, index) => cmux("workspace.reorder", { workspace_id: id, index }),
      },
      openRow
    ),
    ...GROUPS.filter((g) => g.repos.length).flatMap((g) => [
      Divider(),
      header(g.title, () => `${g.repos.filter((r) => openFor(r)).length}/${g.repos.length}`),
      ...g.repos.map(repoRow),
    ]),
    Spacer(),
  ]).padding(8)
);
