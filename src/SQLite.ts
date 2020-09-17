import { BridgeContext } from "doric";

export class Database {
  context: BridgeContext;
  dbId: string;
  private constructor(context: BridgeContext, dbId: string) {
    this.context = context;
    this.dbId = dbId;
  }

  public async execute(
    statement: string,
    parameters?: (string | number | null)[]
  ) {
    await this.context.callNative("sqlite", "execute", {
      statement,
      parameters: parameters || [],
      dbId: this.dbId,
    });
  }
  public async executeQuery(
    statement: string,
    parameters?: (string | number | null)[]
  ) {
    return await this.context.callNative("sqlite", "executeQuery", {
      statement,
      parameters: parameters || [],
      dbId: this.dbId,
    });
  }

  public async close() {
    await this.context.callNative("sqlite", "close", {
      dbId: this.dbId,
    });
  }

  public static async open(context: BridgeContext, fileName: string) {
    const dbId = (await context.callNative("sqlite", "open", {
      fileName,
    })) as string;
    return new Database(context, dbId);
  }
}
