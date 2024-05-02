"use strict";

function $(id) { return document.getElementById(id); }

window.onload = function() {
    if(!window.WebAssembly) {
        alert("Your browser is not supported because it doesn't support WebAssembly");
        return;
    }

    window.settings = {
        wasm_path: "v86/v86.wasm",
        memory_size: 48 * 1024 * 1024,
        vga_memory_size: 8 * 1024 * 1024,
        screen_container: $("screen_container"),
        bios: { url: "images/seabios.bin" },
        vga_bios: { url: "images/vgabios.bin" },
        fda: {
            url: "floppinux.img",
            async: true
        },
        boot_order: parseInt('321', 16),
        autostart: true
    };
    $("screen_container").onclick = function() {
        let pk = document.getElementsByClassName("phone_keyboard")[0];
        pk.style.top = document.body.scrollTop + 100 + "px";
        pk.style.left = document.body.scrollLeft + 100 + "px";
        pk.focus();
    }
    window.emulator = new V86Starter(settings);
}

function restart() {
    if (emulator) {
        emulator.stop();
        window.emulator = new V86Starter(settings);
    }
}
