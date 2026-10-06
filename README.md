# Validando reglas de negocio con SQL Server: un caso práctico con EOMONTH

Materiales de la sesión presentada en **Power Platform Weekend CLM 2026 — Madridejos**.

## Sobre la sesión

La charla muestra cómo trasladar una regla de negocio temporal a SQL Server para validar fechas de abandono en suscripciones mensuales.

El caso se centra en:

- definición del **día ancla** a partir de la fecha de conversión;
- tratamiento de meses con distinta duración;
- cálculo de la **fecha candidata** y la **fecha esperada**;
- clasificación de registros como **correctos**, **excepciones válidas** o **errores**;
- corrección controlada mediante `UPDATE`;
- revalidación antes de decidir `COMMIT` o `ROLLBACK`.

**Alcance del caso:** ciclos mensuales y granularidad diaria.

## Contenido del repositorio

```text
.
├── README.md
├── slides/
│   └── Martin-Viveros, J.I_PPWCLM 2026.pptx
└── sql/
    ├── demo_validacion_correccion_revalidacion.sql
    └── alternativa_datediff_dateadd.sql
```

### Presentación

`slides/Martin-Viveros, J.I_PPWCLM 2026.pptx`

Presentación utilizada durante la sesión.

### Script principal

`sql/demo_validacion_correccion_revalidacion.sql`

Incluye:

1. construcción de la lógica de validación;
2. creación de la vista de resultados;
3. identificación de errores;
4. corrección de los registros mediante `UPDATE`;
5. revalidación;
6. decisión final entre `COMMIT` y `ROLLBACK`.

### Enfoque alternativo

`sql/alternativa_datediff_dateadd.sql`

Implementación alternativa de la misma regla utilizando `DATEDIFF` y `DATEADD`.

Se incluye como ejemplo de otro enfoque posible frente al uso explícito de `EOMONTH`.

## Tecnologías

- Microsoft SQL Server
- SQL Server Management Studio
- T-SQL

## Nota sobre los datos

La base de datos utilizada durante la demostración no se publica en este repositorio.

El objetivo de los materiales es compartir la lógica SQL y la presentación de la sesión.

---

**Juan Ignacio Martín-Viveros**  
Power Platform Weekend CLM 2026
