import {
  Panel,
  Group,
  vlayout,
  layoutConfig,
  Gravity,
  text,
  Text,
  Color,
  navbar,
  modal,
} from "doric";
import { Database } from "./SQLite";

@Entry
class DoricSQLite extends Panel {
  dataBase?: Database;
  onCreate() {
    this.init().then();
  }

  async init() {
    this.dataBase = await Database.open(context, "test");
    if (this.dataBase) {
      await this.dataBase.execute(`CREATE TABLE IF NOT EXISTS FileRecord  (
            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            name Text,
            type Text,
            fid Text,
            cid Text,
            pid Text,
            pc Text,
            extra Text,
            timestamp datetime default (datetime('now', 'localtime'))
       )`);
      const result = await this.dataBase.executeQuery(
        "SELECT * FROM FileRecord WHERE id = ?",
        [2]
      );
      modal(context).alert(JSON.stringify(result));
    }
  }

  onShow() {
    navbar(context).setTitle("DoricSQLite");
  }
  build(rootView: Group): void {
    let number: Text;
    let count = 0;
    vlayout([
      (number = text({
        textSize: 40,
        text: "0",
      })),
      text({
        text: "Click to count",
        textSize: 20,
        backgroundColor: Color.parse("#70a1ff"),
        textColor: Color.WHITE,
        onClick: () => {
          number.text = `${++count}`;
          this.dataBase?.execute(
            "insert into FileRecord (name,type) values (?,?)",
            [`index:${count}`, "test"]
          );
        },
        layoutConfig: layoutConfig().just(),
        width: 200,
        height: 50,
      }),
    ])
      .apply({
        layoutConfig: layoutConfig().just().configAlignment(Gravity.Center),
        width: 200,
        height: 200,
        space: 20,
        border: {
          color: Color.BLUE,
          width: 1,
        },
        gravity: Gravity.Center,
      })
      .in(rootView);
  }
}
