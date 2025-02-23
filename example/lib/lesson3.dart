// Copyright (c) 2013, John Thomas McDole.
/*
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
part of 'learn_gl.dart';

/// Draw a colored triangle and a square, and have them rotate on axis.
/// This lesson is nearly identical to Lesson 2, and we could clean it up...
/// however that's a future lesson.
class Lesson3 extends Lesson {
  late GlProgram program;

  late Buffer triangleVertexPositionBuffer, squareVertexPositionBuffer;
  late Buffer triangleVertexColorBuffer, squareVertexColorBuffer;

  double rTriangle = 0.0, rSquare = 0.0;

  Lesson3() {
    program = new GlProgram(
      '''
          #version 300 es
          precision mediump float;
          out vec4 FragColor;

          in vec4 vColor;

          void main(void) {
            FragColor = vColor;
          }
        ''',
      '''
          #version 300 es
          in vec3 aVertexPosition;
          in vec4 aVertexColor;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          out vec4 vColor;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vColor = aVertexColor;
          }
        ''',
      ['aVertexPosition', 'aVertexColor'],
      ['uMVMatrix', 'uPMatrix'],
    );
    gl.useProgram(program.program);

    // calloc and build the two buffers we need to draw a triangle and box.
    // createBuffer() asks the WebGL system to calloc some data for us
    triangleVertexPositionBuffer = gl.createBuffer();

    // bindBuffer() tells the WebGL system the target of future calls
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexPositionBuffer);
    gl.bufferData(WebGL.ARRAY_BUFFER, new Float32List.fromList([0.0, 1.0, 0.0, -1.0, -1.0, 0.0, 1.0, -1.0, 0.0]),
        WebGL.STATIC_DRAW);

    triangleVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexColorBuffer);
    var colors = [1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0];
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      new Float32List.fromList(colors),
      WebGL.STATIC_DRAW,
    );

    squareVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexPositionBuffer);
    gl.bufferData(WebGL.ARRAY_BUFFER,
        new Float32List.fromList([1.0, 1.0, 0.0, -1.0, 1.0, 0.0, 1.0, -1.0, 0.0, -1.0, -1.0, 0.0]), WebGL.STATIC_DRAW);

    squareVertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexColorBuffer);
    colors = [0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0];
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      new Float32List.fromList(colors),
      WebGL.STATIC_DRAW,
    );

    // Specify the color to clear with (black with 100% alpha) and then enable
    // depth testing.
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
  }

  void drawScene(int viewWidth, int viewHeight, double aspect) {
    // Basic viewport setup and clearing of the screen
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    // Setup the perspective - you might be wondering why we do this every
    // time, and that will become clear in much later lessons. Just know, you
    // are not crazy for thinking of caching this.
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    // First stash the current model view matrix before we start moving around.
    mvPushMatrix();

    mvMatrix.translate([-1.5, 0.0, -7.0]);

    mvPushMatrix();
    mvMatrix.rotateY(radians(rTriangle));

    // Here's that bindBuffer() again, as seen in the constructor
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexPositionBuffer);
    // Set the vertex attribute to the size of each individual element (x,y,z)
    gl.vertexAttribPointer(program.attributes['aVertexPosition']!, 3, WebGL.FLOAT, false, 0, 0);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangleVertexColorBuffer);
    gl.vertexAttribPointer(program.attributes['aVertexColor']!, 4, WebGL.FLOAT, false, 0, 0);

    setMatrixUniforms();
    // Now draw 3 vertices
    gl.drawArrays(WebGL.TRIANGLES, 0, 3);

    mvPopMatrix();

    // Move 3 units to the right
    mvMatrix.translate([3.0, 0.0, 0.0]);
    mvMatrix.rotateX(radians(rSquare));

    // And get ready to draw the square just like we did the triangle...
    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexPositionBuffer);
    gl.vertexAttribPointer(program.attributes['aVertexPosition']!, 3, WebGL.FLOAT, false, 0, 0);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, squareVertexColorBuffer);
    gl.vertexAttribPointer(program.attributes['aVertexColor']!, 4, WebGL.FLOAT, false, 0, 0);

    setMatrixUniforms();
    // Except now draw 2 triangles, re-using the vertices found in the buffer.
    gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);

    // Finally, reset the matrix back to what it was before we moved around.
    mvPopMatrix();
  }

  /// Write the matrix uniforms (model view matrix and perspective matrix) so
  /// WebGL knows what to do with them.
  setMatrixUniforms() {
    gl.uniformMatrix4fv(program.uniforms['uPMatrix']!, false, pMatrix.buf);
    gl.uniformMatrix4fv(program.uniforms['uMVMatrix']!, false, mvMatrix.buf);
  }

  /// Every time the browser tells us to draw the scene, animate is called.
  /// If there's something being movied, this is where that movement i
  /// calculated.
  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;
      rTriangle += (90 * elapsed) / 100.0;
      rSquare += (75 * elapsed) / 100.0;
    }
    lastTime = now;
  }

  void handleKeys() {
    // We're not handling keys right now, but if you want to experiment, here's
    // where you'd get to play around.
  }
}
