package com.example.MotvirsWeb.aplicacion.verificacion;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.LongSupplier;

/** Ventana deslizante en memoria: máximo N eventos por clave dentro de la ventana. */
public class LimitadorTasa {

    private final int maximo;
    private final long ventanaMs;
    private final LongSupplier reloj;
    private final ConcurrentHashMap<String, Deque<Long>> eventos = new ConcurrentHashMap<>();

    public LimitadorTasa(int maximo, long ventanaMs) {
        this(maximo, ventanaMs, System::currentTimeMillis);
    }

    public LimitadorTasa(int maximo, long ventanaMs, LongSupplier reloj) {
        this.maximo = maximo;
        this.ventanaMs = ventanaMs;
        this.reloj = reloj;
    }

    /** @return true si el evento se permite (y se cuenta). */
    public boolean permitir(String clave) {
        long ahora = reloj.getAsLong();
        Deque<Long> q = eventos.computeIfAbsent(clave, k -> new ArrayDeque<>());
        synchronized (q) {
            while (!q.isEmpty() && ahora - q.peekFirst() >= ventanaMs) {
                q.pollFirst();
            }
            if (q.size() >= maximo) {
                return false;
            }
            q.addLast(ahora);
            return true;
        }
    }
}
