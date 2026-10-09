// lifenode.mjs — binary IPC bridge. Tensors live in shm; ids cross the socket.
import { connect } from 'node:net';

const HDR = 16; // [u32 msg_type][u32 tensor_id][u64 length]
const sock = connect('/tmp/nnhost.sock');
const pending = new Map();

function frame(type, tensorId, payload) {
  const buf = Buffer.alloc(HDR + payload.length);
  buf.writeUInt32LE(type, 0);
  buf.writeUInt32LE(tensorId, 4);
  buf.writeBigUInt64LE(BigInt(payload.length), 8);
  payload.copy(buf, HDR);
  return buf;
}

function f32buf(input) {
  const f = Float32Array.from(input);
  return Buffer.from(f.buffer, f.byteOffset, f.byteLength);
}

sock.on('data', (buf) => {
  const type = buf.readUInt32LE(0);
  const id = buf.readUInt32LE(4);
  const len = Number(buf.readBigUInt64LE(8));
  const payload = buf.subarray(HDR, HDR + len);
  const view = new Float32Array(payload.buffer, payload.byteOffset, len >> 2);
  const wait = pending.get(id);
  if (wait) {
    pending.delete(id);
    wait(type, view);
  }
});

function waitFor(tensorId) {
  return new Promise((resolve) => {
    pending.set(tensorId, (_type, view) => resolve(view));
  });
}

export async function dspyStep(tensorId, input) {
  sock.write(frame(0x01, tensorId, f32buf(input)));
  return await waitFor(tensorId);
}
