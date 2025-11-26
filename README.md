# Cómo crear un archivo de volumen simulado de 4 GB con `dd`

Este README explica cómo generar un archivo que simule un volumen de 4 GB usando el comando `dd` en Linux.

---

## Comando para crear el archivo de 4 GB

```
dd if=/dev/zero of=volumen_4GB.img bs=1G count=4

```


### Detalles:

- `if=/dev/zero`: utiliza un flujo continuo de ceros (bytes 0) como entrada.
- `of=volumen_4GB.img`: archivo de salida que se creará, puede llamarse como quieras.
- `bs=1G`: tamaño de bloque de 1 gigabyte.
- `count=4`: número de bloques a escribir, en este caso 4 bloques de 1GB = 4GB totales.



