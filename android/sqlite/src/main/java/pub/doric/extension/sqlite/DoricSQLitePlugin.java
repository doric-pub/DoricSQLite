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

import android.os.Environment;

import com.github.pengfeizhou.jscore.JSArray;
import com.github.pengfeizhou.jscore.JSObject;
import com.github.pengfeizhou.jscore.JavaValue;

import org.json.JSONArray;

import java.io.File;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import pub.doric.DoricContext;
import pub.doric.extension.bridge.DoricMethod;
import pub.doric.extension.bridge.DoricPlugin;
import pub.doric.extension.bridge.DoricPromise;
import pub.doric.plugin.DoricJavaPlugin;

/**
 * @Description: pub.doric.extension.sqlite
 * @Author: pengfei.zhou
 * @CreateDate: 2020/9/17
 */
@DoricPlugin(name = "sqlite")
public class DoricSQLitePlugin extends DoricJavaPlugin {
    private ConcurrentHashMap<String, DoricSQLiteDatabase> sqLiteDatabaseMap = new ConcurrentHashMap<>();
    private AtomicInteger atomicInteger = new AtomicInteger(0);

    public DoricSQLitePlugin(DoricContext doricContext) {
        super(doricContext);
    }

    @DoricMethod
    public void open(JSObject argument, DoricPromise promise) {
        String fileName = argument.getProperty("fileName").asString().value();
        DoricSQLiteDatabase database = new DoricSQLiteDatabase(getDoricContext().getContext().getDatabasePath(fileName));
        String dbId = String.valueOf(atomicInteger.addAndGet(1));
        sqLiteDatabaseMap.put(dbId, database);
        promise.resolve(new JavaValue(dbId));
    }

    @DoricMethod
    public void close(JSObject argument, DoricPromise promise) {
        String dbId = argument.getProperty("dbId").asString().value();
        DoricSQLiteDatabase database = sqLiteDatabaseMap.remove(dbId);
        if (database != null) {
            database.close();
        }
        promise.resolve();
    }

    @DoricMethod
    public void execute(JSObject argument, DoricPromise promise) {
        String dbId = argument.getProperty("dbId").asString().value();
        String statement = argument.getProperty("statement").asString().value();
        JSArray parameters = argument.getProperty("parameters").asArray();
        DoricSQLiteDatabase database = sqLiteDatabaseMap.get(dbId);
        if (database != null) {
            database.execute(statement, parameters.toArray());
            promise.resolve();
        } else {
            promise.reject(new JavaValue("Cannot find db for " + dbId));
        }
    }

    @DoricMethod
    public void executeUpdateDelete(JSObject argument, DoricPromise promise) {
        String dbId = argument.getProperty("dbId").asString().value();
        String statement = argument.getProperty("statement").asString().value();
        JSArray parameters = argument.getProperty("parameters").asArray();
        DoricSQLiteDatabase database = sqLiteDatabaseMap.get(dbId);
        if (database != null) {
            promise.resolve(new JavaValue(database.executeUpdateDelete(statement, parameters.toArray())));
        } else {
            promise.reject(new JavaValue("Cannot find db for " + dbId));
        }
    }

    @DoricMethod
    public void executeInsert(JSObject argument, DoricPromise promise) {
        String dbId = argument.getProperty("dbId").asString().value();
        String statement = argument.getProperty("statement").asString().value();
        JSArray parameters = argument.getProperty("parameters").asArray();
        DoricSQLiteDatabase database = sqLiteDatabaseMap.get(dbId);
        if (database != null) {
            promise.resolve(new JavaValue(database.executeInsert(statement, parameters.toArray())));
        } else {
            promise.reject(new JavaValue("Cannot find db for " + dbId));
        }
    }

    @DoricMethod
    public void executeQuery(JSObject argument, DoricPromise promise) {
        String dbId = argument.getProperty("dbId").asString().value();
        String statement = argument.getProperty("statement").asString().value();
        JSArray parameters = argument.getProperty("parameters").asArray();
        DoricSQLiteDatabase database = sqLiteDatabaseMap.get(dbId);
        if (database != null) {
            JSONArray jsonArray = database.executeQuery(statement, parameters.toArray());
            promise.resolve(new JavaValue(jsonArray));
        } else {
            promise.reject(new JavaValue("Cannot find db for " + dbId));
        }
    }

    @Override
    public void onTearDown() {
        super.onTearDown();
        for (DoricSQLiteDatabase database : sqLiteDatabaseMap.values()) {
            database.close();
        }
        sqLiteDatabaseMap.clear();
    }
}
