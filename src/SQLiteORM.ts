import { BridgeContext, ClassType } from "doric";
import { Database } from "./sqlite";
import "reflect-metadata";

const METADATA_ENTITY = "sqlite_orm:entity";
const METADATA_COLUMS = "sqlite_orm:colums";

type ColumType = "TEXT" | "INTEGER" | "NUMERIC" | "NULL" | "BLOB" | "INTEGER";

type ColumOption = {
  name: string;
  type: ColumType;
  primary?: boolean;
  autoIncrement?: boolean;
  nonull?: boolean;
};

type TableOption = {
  name: string;
};

export function Entity(name?: string) {
  return (clz: ClassType<object>) => {
    const tableName = name || clz.name;
    Reflect.defineMetadata(
      METADATA_ENTITY,
      {
        name: tableName,
      },
      clz
    );
  };
}

export function Column(name?: string) {
  return (target: object, propertyKey: string) => {
    const typeClz = Reflect.getMetadata("design:type", target, propertyKey);
    const columnName = name || propertyKey;
    let type: ColumType = "TEXT";
    if (typeClz === Number) {
      type = "NUMERIC";
    }
    const columOptions = Reflect.getMetadata(
      METADATA_COLUMS,
      target.constructor
    ) as ColumOption[];
    if (columOptions) {
      columOptions.push({
        name: columnName,
        type,
      });
    } else {
      Reflect.defineMetadata(
        METADATA_COLUMS,
        [
          {
            name: columnName,
            type,
          },
        ],
        target.constructor
      );
    }
  };
}

function PrimaryGeneratedColumn(name?: string) {
  return (target: object, propertyKey: string) => {
    const typeClz = Reflect.getMetadata("design:type", target, propertyKey);
    if (typeClz !== Number) {
      throw new Error(`PrimaryGeneratedColumn type must be number`);
    }
    const columnName = name || propertyKey;
    const columOptions = Reflect.getMetadata(
      METADATA_COLUMS,
      target.constructor
    ) as ColumOption[];
    if (columOptions) {
      columOptions.push({
        name: columnName,
        type: "INTEGER",
        primary: true,
        autoIncrement: true,
        nonull: true,
      });
    } else {
      Reflect.defineMetadata(
        METADATA_COLUMS,
        [
          {
            name: columnName,
            type: "INTEGER",
            primary: true,
            autoIncrement: true,
            nonull: true,
          },
        ],
        target.constructor
      );
    }
  };
}

@Entity()
export class Record {
  @PrimaryGeneratedColumn()
  id?: number;
  @Column()
  name?: string;
  @Column()
  type?: string;
  @Column()
  extra?: string;
}

export class SQLiteConnection {
  db: Database;
  private constructor(db: Database) {
    this.db = db;
  }
  static async connect(context: BridgeContext, fileName: string) {
    const db = await Database.open(context, fileName);
    return new SQLiteConnection(db);
  }

  async getRepository<Entity>(clz: ClassType<Entity>) {
    const repository = new Repository(this.db, clz);
    await repository.create();
    return repository;
  }
}

type ConditionOption<Entity> = {
  [P in keyof Entity]?: Entity[P];
};

type QueryOption<Entity> = {
  select?: (keyof Entity)[];
  where?: ConditionOption<Entity>;
};

export class Repository<Entity> {
  db: Database;
  tableOption: TableOption;
  columOptions: ColumOption[];
  constructor(db: Database, clz: ClassType<Entity>) {
    this.db = db;
    this.tableOption = Reflect.getMetadata(METADATA_ENTITY, clz) as TableOption;
    this.columOptions = Reflect.getMetadata(
      METADATA_COLUMS,
      clz
    ) as ColumOption[];
  }
  async create() {
    this.db.execute(`CREATE TABLE IF NOT EXISTS ${this.tableOption.name}  (
            ${this.columOptions
              .map(
                (e) =>
                  `${e.name} ${e.type}${e.primary ? " PRIMARY KEY" : ""}${
                    e.autoIncrement ? " AUTOINCREMENT" : ""
                  }${e.nonull ? " NOT NULL" : ""} `
              )
              .join(",")}
       )`);
  }
  async query(): Promise<Entity[]> {
    const ret = await this.db.executeQuery(
      `SELECT * FROM ${this.tableOption.name}`
    );
    return ret as Entity[];
  }
  async update(entity: Entity) {}
  async insert(entity: Entity) {
    const columOptions = this.columOptions.filter((e) => !e.autoIncrement);
    const ret = await this.db.executeQuery(
      `INSERT INTO ${this.tableOption.name} (${columOptions
        .map((e) => e.name)
        .join(",")}) VALUES (${new Array(columOptions.length)
        .fill("?")
        .join(",")})`,
      columOptions.map((e) => Reflect.get(entity as Object, e.name))
    );
    return ret;
  }
  async delete(entity: Partial<Entity>) {
    const ret = await this.db.executeUpdateDelete(
      `DELETE FROM ${this.tableOption.name} WHERE entity = ${entity}`
    );
    return ret;
  }
}
