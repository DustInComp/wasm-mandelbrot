// colors can be changed via colorMemory.buffer
let colors = [[0,0,0],[24,8,8],[48,16,16],[72,24,24],[96,32,32],[120,40,40],[144,48,48],[168,56,56],[192,64,64],[176,80,64],[160,96,64],[144,112,64],[128,128,64],[112,144,64],[96,160,64],[80,176,64],[64,192,64],[64,176,80],[64,160,96],[64,144,112],[64,128,128],[64,112,144],[64,96,160],[64,80,176],[64,64,192],[56,56,168],[48,48,144],[40,40,120],[32,32,96],[24,24,72],[16,16,48],[8,8,24]]
const colorMemory = new WebAssembly.Memory({initial:1})
new Uint8Array(colorMemory.buffer).set(colors.flatMap(rgb=>rgb.concat(255)), 0)
// append a color for the set itself
new Uint8Array(colorMemory.buffer).set([255,255,255,255], colors.length*4)

let center = [0,0], // complex number at center of canvas
    width = innerWidth,
    height = innerHeight
    scale = 0.005, // coordinate units per pixel
    depth = 200 // max iterations of z^2+c formula
let canvas, ctx
let colorsModule, getColor
let rendererModule, wasmRender, rendererMemory

async function setup() {
    canvas = document.createElement('canvas'),
    ctx = canvas.getContext('2d')
    canvas.width = width
    canvas.height = height
    canvas.addEventListener('click', e => {
        if (e.button === 0) {
            let factor = e.shiftKey ? 2 : 1

            if (!e.ctrlKey) {
                center[0] += scale*(e.offsetX - width/2)
                center[1] -= scale*(e.offsetY - height/2)

                scale /= 2 * factor
                depth += 50 * factor
            } else {
                scale *= 2 * factor
                depth = Math.max(1, depth - 50*factor)
            }
            render()
        }
    })
    document.body.appendChild(canvas)

    let bytes = await (await fetch('src/wasm/colors.wasm')).arrayBuffer()

    colorsModule = await WebAssembly.instantiate(bytes, {js:{length:colors.length, colors:colorMemory}})
    getColor = colorsModule.instance.exports.getColor

    bytes = await (await fetch('src/wasm/renderer.wasm')).arrayBuffer()
    rendererModule = await WebAssembly.instantiate(bytes, {js:{width, height, getColor}})
    wasmRender = rendererModule.instance.exports.render
    rendererMemory = rendererModule.instance.exports.imageData
    render()
}

async function render() {
    let left = center[0] - scale * canvas.width/2,
        top = center[1] + scale * canvas.height/2

    requestAnimationFrame(() => {
        // rgba data is stored in the memory
        wasmRender(left, top, scale, depth)
        // fill new ImageData with module's memory and put on canvas
        let imageData = new ImageData(width, height)
        imageData.data.set(new Uint8Array(rendererMemory.buffer.slice(0, width*height*4)), 0)
        ctx.putImageData(imageData, 0, 0)
    })
}