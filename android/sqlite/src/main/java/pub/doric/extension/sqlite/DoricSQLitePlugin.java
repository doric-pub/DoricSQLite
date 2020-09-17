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

import com.github.pengfeizhou.jscore.JSObject;

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
    public DoricSQLitePlugin(DoricContext doricContext) {
        super(doricContext);
    }

    @DoricMethod
    public void connect(JSObject argument, DoricPromise promise) {
        
    }
}
