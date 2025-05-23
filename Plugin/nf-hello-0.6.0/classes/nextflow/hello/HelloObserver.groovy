/*
 * Copyright 2021, Seqera Labs
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package nextflow.hello

import groovy.transform.CompileStatic
import groovy.util.logging.Slf4j
import nextflow.Session
import nextflow.trace.TraceObserver

/**
 * Example workflow events observer
 *
 * @author Paolo Di Tommaso <paolo.ditommaso@gmail.com>
 */
@Slf4j
@CompileStatic
class HelloObserver implements TraceObserver {

    @Override
    void onFlowCreate(Session session) {
        log.info "Pipeline is starting! 🚀 This is a change in the plugin!"

        // Define the file path
        //def filePath = "/home/philipp/start_signal.txt"
        def filePath = "/data/start_signal.txt"

        // Create or open the file and write 'start'
        new File(filePath).withWriter('UTF-8') { writer ->
        writer.writeLine('start')}

    }

    @Override
    void onFlowComplete() {
        log.info "Pipeline complete! 👋 This line was also changed!"

        // Define the file path
        //def filePath = "/home/philipp/stop_signal.txt"
        def filePath = "/data/stop_signal.txt"

        // Create or open the file and write 'stop'
        new File(filePath).withWriter('UTF-8') { writer ->
        writer.writeLine('stop')}
    }
}
