// installed by herdr
// managed by herdr; reinstalling or updating the integration overwrites this file.
// add custom hooks/plugins beside this file instead of editing it.
// HERDR_INTEGRATION_ID=opencode
// HERDR_INTEGRATION_VERSION=10
// NOTE: manually ported to the OpenCode 2 plugin API; reinstalling herdr's
// integration restores the OpenCode 1 version, which will not load in v2.

import net from "node:net";

const SOURCE = "herdr:opencode";
const AGENT = "opencode";
let reportSeq = Date.now() * 1000;
let requestChain = Promise.resolve();
let reportedRootSessionID;

// Track child sessions so their events cannot replace the pane's root session.
// Their user prompts still project state without attaching the child session id.
const childSessions = new Set();
const CHILD_EVENT_STATES = new Map([
  ["permission.asked", "blocked"],
  ["form.created", "blocked"],
  ["permission.replied", "working"],
  ["form.replied", "working"],
  ["form.cancelled", "working"],
]);

function nextReportSeq() {
  reportSeq += 1;
  return reportSeq;
}

function sessionIDFromData(data) {
  return typeof data?.sessionID === "string" && data.sessionID
    ? data.sessionID
    : undefined;
}

const SESSION_STATE_BY_STATUS = new Map([
  ["idle", "idle"],
  ["retry", "working"],
  ["busy", "working"],
]);

function stateFromSessionStatus(status) {
  const kind = typeof status === "string" ? status : status?.type;
  return typeof kind === "string"
    ? SESSION_STATE_BY_STATUS.get(kind.toLowerCase())
    : undefined;
}

function request(method, params) {
  const pending = requestChain.then(() => requestOnce(method, params));
  requestChain = pending.catch(() => {});
  return pending;
}

function requestOnce(method, params) {
  const paneId = process.env.HERDR_PANE_ID;
  const socketPath = process.env.HERDR_SOCKET_PATH;

  if (!paneId || !socketPath) {
    return Promise.resolve();
  }

  const socketEndpoint =
    process.platform === "win32" ? `\\\\.\\pipe\\${socketPath}` : socketPath;

  const requestId = `${SOURCE}:${Date.now()}:${Math.floor(Math.random() * 1_000_000)
    .toString()
    .padStart(6, "0")}`;
  const request = {
    id: requestId,
    method,
    params: {
      pane_id: paneId,
      source: SOURCE,
      agent: AGENT,
      seq: nextReportSeq(),
      ...params,
    },
  };

  return new Promise((resolve) => {
    const client = net.createConnection(socketEndpoint, () => {
      client.write(`${JSON.stringify(request)}\n`);
    });

    const finish = () => {
      client.destroy();
      resolve();
    };

    client.setTimeout(500, finish);
    client.on("data", finish);
    client.on("error", finish);
    client.on("end", finish);
    client.on("close", resolve);
  });
}

function reportSession(sessionID) {
  if (!sessionID) {
    return Promise.resolve();
  }
  return request("pane.report_agent_session", { agent_session_id: sessionID });
}

function reportState(state, sessionID) {
  const params = { state };
  if (sessionID) {
    reportedRootSessionID = sessionID;
    params.agent_session_id = sessionID;
  }
  return request("pane.report_agent", params);
}

async function handleEvent(event) {
  const type = event?.type;
  const data = event?.data ?? {};
  const sessionID = sessionIDFromData(data);
  // Form payloads carry their session under data.form (v2 replaced question
  // events with forms).
  const formSessionID = sessionIDFromData(data.form);

  if (type === "session.created" && data.parentID) {
    childSessions.add(data.sessionID);
  }

  const effectiveSessionID = sessionID ?? formSessionID;
  if (effectiveSessionID && childSessions.has(effectiveSessionID)) {
    const state = CHILD_EVENT_STATES.get(type);
    if (state) {
      await reportState(state);
    }
    return;
  }

  switch (type) {
    case "session.created":
      // Creation is server-global, so an attached client may own it. The
      // TUI plugin separately reports the root selected in this pane.
      if (!data.parentID) {
        reportedRootSessionID = effectiveSessionID;
      }
      break;
    case "session.status": {
      const state = stateFromSessionStatus(data.status);
      if (state) {
        await reportState(state, sessionID);
      } else {
        await reportSession(sessionID);
      }
      break;
    }
    case "session.step.started":
    case "session.text.started":
    case "session.tool.called":
    case "session.tool.success":
    case "session.tool.failed":
    case "session.retry.scheduled":
    case "session.compaction.started":
    case "session.compaction.ended":
    case "session.compaction.failed":
    case "permission.replied":
    case "form.replied":
    case "form.cancelled":
      await reportState("working", effectiveSessionID);
      break;
    case "permission.asked":
    case "form.created":
    case "session.execution.failed":
    case "session.step.failed":
      await reportState("blocked", effectiveSessionID);
      break;
    case "session.idle":
      await reportState("idle", sessionID);
      break;
    case "session.deleted":
      break;
    default:
      break;
  }
}

export default {
  id: "herdr.opencode.agent-state",
  setup: async (ctx) => {
    if (
      process.env.HERDR_ENV !== "1" ||
      !process.env.HERDR_SOCKET_PATH ||
      !process.env.HERDR_PANE_ID
    ) {
      return;
    }

    const controller = new AbortController();
    const pump = (async () => {
      try {
        for await (const event of ctx.event.subscribe({
          signal: controller.signal,
        })) {
          try {
            await handleEvent(event);
          } catch {
            // Best-effort reporting; never let one event kill the stream.
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) {
          console.error("[herdr] opencode event stream failed:", error);
        }
      }
    })();

    return async () => {
      controller.abort();
      await pump.catch(() => {});
    };
  },
};
