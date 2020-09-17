import { BridgeContext } from "doric";

export class Database {
  context: BridgeContext;
  constructor(context: BridgeContext, fileName: string) {
    this.context = context;
    this.context.callNative("sqlite", "connect");
  }
}
