-- Supplier portal invoices. The amount of the target invoice (INV-20507) is the
-- per-player evidence: seeded as a placeholder and set at startup by the
-- `place-evidence` service. Never commit a real evidence value.
CREATE TABLE IF NOT EXISTS invoices (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  reference VARCHAR(32) NOT NULL UNIQUE,
  vendor    VARCHAR(64) NOT NULL,
  amount    DECIMAL(10,2) NOT NULL,
  status    VARCHAR(16) NOT NULL
);

INSERT INTO invoices (reference, vendor, amount, status) VALUES
  ('INV-20481', 'acme-supplies', 4210.00, 'approved'),
  ('INV-20492', 'acme-supplies', 980.50, 'pending'),
  ('INV-20507', 'globex-logistics', 0.00, 'pending');
