/*
 * Copyright [2019] [Doric.Pub]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package pub.doric.extension.sqlite;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteStatement;
import android.util.Base64;

import com.github.pengfeizhou.jscore.JSValue;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;

/**
 * @Description: pub.doric.extension.sqlite
 * @Author: pengfei.zhou
 * @CreateDate: 2020/9/17
 */
public class DoricSQLiteDatabase {
    private SQLiteDatabase db;

    public DoricSQLiteDatabase(File file) {
        this.db = SQLiteDatabase.openOrCreateDatabase(file, null);
    }

    public void close() {
        this.db.close();
        this.db = null;
    }

    public boolean isClosed() {
        return this.db == null;
    }

    public void execute(String query, JSValue[] arguments) {
        SQLiteStatement statement = prepareSQLiteStatement(query, arguments);
        this.db.beginTransaction();
        try {
            statement.execute();
            this.db.setTransactionSuccessful();
        } finally {
            this.db.endTransaction();
        }
    }

    public JSONArray executeQuery(String query, JSValue[] arguments) {
        String[] params = new String[arguments.length];
        for (int i = 0; i < arguments.length; i++) {
            JSValue argument = arguments[i];
            if (argument.isString()) {
                params[i] = argument.asString().value();
            } else if (argument.isNumber()) {
                double v = argument.asNumber().toDouble();
                if (v == (long) v) {
                    params[i] = String.valueOf((long) v);
                } else {
                    params[i] = String.valueOf(v);
                }
            } else {
                params[i] = "";
            }
        }
        this.db.beginTransaction();
        Cursor cursor = null;
        try {
            JSONArray jsonArray = new JSONArray();
            cursor = this.db.rawQuery(query, params);
            if (cursor != null && cursor.moveToFirst()) {
                int colCount = cursor.getColumnCount();
                String key;
                int curType;
                do {
                    JSONObject jsonObject = new JSONObject();
                    for (int i = 0; i < colCount; i++) {
                        key = cursor.getColumnName(i);
                        curType = cursor.getType(i);
                        switch (curType) {
                            case Cursor.FIELD_TYPE_NULL:
                                jsonObject.put(key, JSONObject.NULL);
                                break;
                            case Cursor.FIELD_TYPE_INTEGER:
                                jsonObject.put(key, cursor.getLong(i));
                                break;
                            case Cursor.FIELD_TYPE_FLOAT:
                                jsonObject.put(key, cursor.getDouble(i));
                                break;
                            case Cursor.FIELD_TYPE_BLOB:
                                jsonObject.put(key, new String(Base64.encode(cursor.getBlob(i), Base64.DEFAULT)));
                                break;
                            case Cursor.FIELD_TYPE_STRING:
                            default:
                                jsonObject.put(key, cursor.getString(i));
                                break;
                        }
                    }
                    jsonArray.put(jsonObject);
                } while (cursor.moveToNext());
            }
            this.db.setTransactionSuccessful();
            return jsonArray;
        } catch (JSONException e) {
            e.printStackTrace();
        } finally {
            this.db.endTransaction();
            if (cursor != null) {
                cursor.close();
            }
        }
        return null;
    }

    private SQLiteStatement prepareSQLiteStatement(String query, JSValue[] arguments) {
        SQLiteStatement statement = this.db.compileStatement(query);
        for (int i = 0; i < arguments.length; i++) {
            JSValue argument = arguments[i];
            if (argument.isString()) {
                statement.bindString(i + 1, argument.asString().value());
            } else if (argument.isNumber()) {
                double v = argument.asNumber().toDouble();
                if (v == (long) v) {
                    statement.bindLong(i + 1, (long) v);
                } else {
                    statement.bindDouble(i + 1, v);
                }
            } else {
                statement.bindNull(i + 1);
            }
        }
        return statement;
    }
}
