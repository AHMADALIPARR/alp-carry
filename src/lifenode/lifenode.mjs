# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

#!/usr/bin/env node
/* Life node — 16-byte header, no JSON on the data path. */
import { createServer } from 'node:net';

const HDR = 16;
const MSG = { TELEMETRY: 0x01, CONSTRAINT: 0x02, RESYNTH: 0x03 };

function frame(type, id, body) {
  const h = Buffer.alloc(HDR);
  h.writeUInt32LE(type, 0);
  h.writeUInt32LE(id, 4);
  h.writeBigUInt64LE(BigInt(body.length), 8);
  return Buffer.concat([h, body]);
}

function handle(type, id, payload, sock) {
  if (type === MSG.TELEMETRY) {
    const verdict = payload.readBigUInt64LE(0);
    if (verdict === 0xFFFFFFFFFFFFFFFFn) {
      sock.write(frame(MSG.RESYNTH, id, Buffer.alloc(0)));
      console.log('[lifenode] totality fallback — resynthesis requested');
    }
  } else if (type === MSG.CONSTRAINT) {
    console.log('[lifenode] new constraint proposal received');
  }
}

const server = createServer((sock) => {
  let pending = Buffer.alloc(0);
  sock.on('data', (chunk) => {
    pending = Buffer.concat([pending, chunk]);
    while (pending.length >= HDR) {
      const type = pending.readUInt32LE(0);
      const id = pending.readUInt32LE(4);
      const len = Number(pending.readBigUInt64LE(8));
      if (pending.length < HDR + len) break;
      const payload = pending.subarray(HDR, HDR + len);
      pending = pending.subarray(HDR + len);
      handle(type, id, payload, sock);
    }
  });
});

server.listen('/tmp/lifenode.sock', () =>
  console.log('[lifenode] listening on /tmp/lifenode.sock'));
