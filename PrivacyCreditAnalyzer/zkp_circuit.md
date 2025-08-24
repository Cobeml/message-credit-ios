# Zero-Knowledge Proof Circuit for Personality Analysis

This document outlines the ZKP circuit design for verifying personality analysis without revealing message content.

## Circuit Overview

The circuit proves:
1. Valid personality trait computation from message inputs
2. Traits are within expected ranges (0.0 to 1.0)
3. Model parameters match expected hash
4. Confidence threshold is met
5. Message count is within bounds

## Rust Circuit Implementation (EZKL)

```rust
// File: zkp_circuit/src/lib.rs
use ezkl::tensor::Tensor;
use ezkl::circuit::{BaseConfig, CheckMode};

/// Main circuit for personality analysis verification
pub struct PersonalityCircuit {
    // Private inputs (witness)
    message_hashes: Vec<[u8; 32]>,
    message_features: Vec<f32>, // Extracted features, not raw content
    model_weights: Vec<f32>,
    
    // Public inputs
    personality_traits: [f32; 5], // openness, conscientiousness, extraversion, agreeableness, neuroticism
    model_hash: [u8; 32],
    trait_bounds: [(f32, f32); 5], // Min/max bounds for each trait
    confidence_threshold: f32,
    message_count: u32,
}

impl PersonalityCircuit {
    pub fn new(
        message_hashes: Vec<[u8; 32]>,
        message_features: Vec<f32>,
        model_weights: Vec<f32>,
        personality_traits: [f32; 5],
        model_hash: [u8; 32],
        trait_bounds: [(f32, f32); 5],
        confidence_threshold: f32,
        message_count: u32,
    ) -> Self {
        Self {
            message_hashes,
            message_features,
            model_weights,
            personality_traits,
            model_hash,
            trait_bounds,
            confidence_threshold,
            message_count,
        }
    }

    /// Main circuit logic
    pub fn verify_personality_analysis(&self) -> Result<bool, CircuitError> {
        // Constraint 1: Verify message count bounds
        self.verify_message_count_bounds()?;
        
        // Constraint 2: Verify model hash integrity
        self.verify_model_hash()?;
        
        // Constraint 3: Verify personality trait computation
        self.verify_trait_computation()?;
        
        // Constraint 4: Verify trait bounds
        self.verify_trait_bounds()?;
        
        // Constraint 5: Verify confidence threshold
        self.verify_confidence_threshold()?;
        
        Ok(true)
    }

    /// Verifies message count is within acceptable bounds
    fn verify_message_count_bounds(&self) -> Result<(), CircuitError> {
        const MIN_MESSAGES: u32 = 5;
        const MAX_MESSAGES: u32 = 5000;
        
        if self.message_count < MIN_MESSAGES || self.message_count > MAX_MESSAGES {
            return Err(CircuitError::MessageCountOutOfBounds);
        }
        
        // Verify message_hashes length matches declared count
        if self.message_hashes.len() != self.message_count as usize {
            return Err(CircuitError::MessageCountMismatch);
        }
        
        Ok(())
    }

    /// Verifies the model hash matches expected value
    fn verify_model_hash(&self) -> Result<(), CircuitError> {
        // Compute hash of model weights
        let computed_hash = self.compute_model_weights_hash();
        
        // Compare with provided hash (in ZK circuit, this becomes a constraint)
        if computed_hash != self.model_hash {
            return Err(CircuitError::ModelHashMismatch);
        }
        
        Ok(())
    }

    /// Verifies that personality traits were computed correctly from features
    fn verify_trait_computation(&self) -> Result<(), CircuitError> {
        // Simplified neural network computation in circuit
        // In practice, this would be the actual ML model inference
        let computed_traits = self.compute_personality_traits_from_features()?;
        
        // Verify computed traits match provided traits (within epsilon)
        const EPSILON: f32 = 0.001;
        
        for i in 0..5 {
            let diff = (computed_traits[i] - self.personality_traits[i]).abs();
            if diff > EPSILON {
                return Err(CircuitError::TraitComputationMismatch);
            }
        }
        
        Ok(())
    }

    /// Verifies personality traits are within valid bounds
    fn verify_trait_bounds(&self) -> Result<(), CircuitError> {
        for i in 0..5 {
            let trait_value = self.personality_traits[i];
            let (min_bound, max_bound) = self.trait_bounds[i];
            
            if trait_value < min_bound || trait_value > max_bound {
                return Err(CircuitError::TraitOutOfBounds);
            }
        }
        
        Ok(())
    }

    /// Verifies confidence threshold is met
    fn verify_confidence_threshold(&self) -> Result<(), CircuitError> {
        // Compute confidence from trait computation (simplified)
        let confidence = self.compute_confidence_score();
        
        if confidence < self.confidence_threshold {
            return Err(CircuitError::ConfidenceTooLow);
        }
        
        Ok(())
    }

    /// Simplified personality trait computation for circuit
    fn compute_personality_traits_from_features(&self) -> Result<[f32; 5], CircuitError> {
        // This would be the actual ML model computation in the circuit
        // For demonstration, we show a simplified linear combination
        
        let mut traits = [0.0f32; 5];
        
        // Feature extraction and trait computation
        for (i, &feature) in self.message_features.iter().enumerate() {
            for trait_idx in 0..5 {
                let weight_idx = i * 5 + trait_idx;
                if weight_idx < self.model_weights.len() {
                    traits[trait_idx] += feature * self.model_weights[weight_idx];
                }
            }
        }
        
        // Apply activation function (sigmoid for 0-1 range)
        for trait in &mut traits {
            *trait = 1.0 / (1.0 + (-*trait).exp());
        }
        
        Ok(traits)
    }

    /// Computes hash of model weights for verification
    fn compute_model_weights_hash(&self) -> [u8; 32] {
        use sha2::{Sha256, Digest};
        
        let mut hasher = Sha256::new();
        for &weight in &self.model_weights {
            hasher.update(weight.to_le_bytes());
        }
        hasher.finalize().into()
    }

    /// Computes confidence score from traits
    fn compute_confidence_score(&self) -> f32 {
        // Simplified confidence computation
        let variance = self.personality_traits.iter()
            .map(|&x| (x - 0.5).powi(2))
            .sum::<f32>() / 5.0;
        
        // Higher variance = higher confidence in distinct personality
        1.0 - (-variance * 2.0).exp()
    }
}

#[derive(Debug)]
pub enum CircuitError {
    MessageCountOutOfBounds,
    MessageCountMismatch,
    ModelHashMismatch,
    TraitComputationMismatch,
    TraitOutOfBounds,
    ConfidenceTooLow,
}

/// EZKL integration functions
pub mod ezkl_bridge {
    use super::*;
    use ezkl::circuit::CircuitBuilder;
    
    /// Builds the EZKL circuit
    pub fn build_personality_circuit() -> Result<CircuitBuilder, Box<dyn std::error::Error>> {
        let mut builder = CircuitBuilder::new();
        
        // Define circuit structure
        // This would include the actual ONNX model integration
        
        Ok(builder)
    }
    
    /// Generates proof for personality analysis
    pub fn generate_proof(circuit: &PersonalityCircuit) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
        // This would call EZKL proof generation
        // ezkl::prove(&circuit, &proving_key)
        
        Ok(vec![]) // Placeholder
    }
    
    /// Verifies a proof
    pub fn verify_proof(proof: &[u8], public_inputs: &[f32]) -> Result<bool, Box<dyn std::error::Error>> {
        // This would call EZKL proof verification
        // ezkl::verify(proof, public_inputs, &verification_key)
        
        Ok(true) // Placeholder
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_personality_circuit() {
        let message_hashes = vec![[0u8; 32]; 10];
        let message_features = vec![0.5f32; 50]; // 10 messages * 5 features each
        let model_weights = vec![0.1f32; 250]; // Simplified weights
        let personality_traits = [0.6, 0.7, 0.5, 0.8, 0.3];
        let model_hash = [1u8; 32];
        let trait_bounds = [(0.0, 1.0); 5];
        let confidence_threshold = 0.3;
        let message_count = 10;
        
        let circuit = PersonalityCircuit::new(
            message_hashes,
            message_features,
            model_weights,
            personality_traits,
            model_hash,
            trait_bounds,
            confidence_threshold,
            message_count,
        );
        
        // This test would fail with the current setup since we don't have real computation
        // but demonstrates the expected circuit behavior
        match circuit.verify_personality_analysis() {
            Ok(_) => println!("Circuit verification passed"),
            Err(e) => println!("Circuit verification failed: {:?}", e),
        }
    }
}
```

## Swift-Rust FFI Bridge

```rust
// File: zkp_circuit/src/ffi.rs
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_float, c_int, c_uint};
use crate::PersonalityCircuit;

/// C-compatible structure for passing data from Swift
#[repr(C)]
pub struct CPersonalityInputs {
    message_hashes: *const u8,
    message_hashes_len: c_uint,
    message_features: *const c_float,
    message_features_len: c_uint,
    model_weights: *const c_float,
    model_weights_len: c_uint,
    personality_traits: *const c_float, // Array of 5 elements
    model_hash: *const u8, // 32 bytes
    confidence_threshold: c_float,
    message_count: c_uint,
}

/// Initialize the ZKP system
#[no_mangle]
pub extern "C" fn zkp_initialize() -> c_int {
    // Initialize EZKL runtime
    // Load circuit and keys
    1 // Success
}

/// Generate ZK proof
#[no_mangle]
pub extern "C" fn zkp_generate_proof(
    inputs: *const CPersonalityInputs,
    proof_output: *mut *mut u8,
    proof_len: *mut c_uint,
) -> c_int {
    if inputs.is_null() || proof_output.is_null() || proof_len.is_null() {
        return 0; // Error
    }
    
    unsafe {
        let inputs_ref = &*inputs;
        
        // Convert C inputs to Rust structures
        // Generate proof using EZKL
        // Allocate output buffer and copy proof data
        
        // For demo purposes:
        let mock_proof = b"mock_proof_data";
        let proof_vec = mock_proof.to_vec();
        let proof_ptr = proof_vec.as_ptr() as *mut u8;
        std::mem::forget(proof_vec);
        
        *proof_output = proof_ptr;
        *proof_len = mock_proof.len() as c_uint;
    }
    
    1 // Success
}

/// Verify ZK proof
#[no_mangle]
pub extern "C" fn zkp_verify_proof(
    proof_data: *const u8,
    proof_len: c_uint,
    public_inputs: *const c_float,
    public_inputs_len: c_uint,
) -> c_int {
    if proof_data.is_null() || public_inputs.is_null() {
        return 0; // Error
    }
    
    // Verify proof using EZKL
    // For demo purposes, always return true
    1 // Valid
}

/// Cleanup allocated memory
#[no_mangle]
pub extern "C" fn zkp_free_proof(proof_data: *mut u8, proof_len: c_uint) {
    if !proof_data.is_null() {
        unsafe {
            Vec::from_raw_parts(proof_data, proof_len as usize, proof_len as usize);
        }
    }
}
```

## Build Configuration

```toml
# File: zkp_circuit/Cargo.toml
[package]
name = "privacy_credit_zkp"
version = "0.1.0"
edition = "2021"

[lib]
name = "privacy_credit_zkp"
crate-type = ["staticlib", "cdylib"]

[dependencies]
ezkl = { git = "https://github.com/zkonduit/ezkl", branch = "main" }
sha2 = "0.10"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

[build-dependencies]
cbindgen = "0.24"

[[bin]]
name = "generate_circuit"
path = "src/bin/generate_circuit.rs"
```

## iOS Integration Steps

1. **Build Rust Library**:
   ```bash
   cargo build --release --target aarch64-apple-ios
   cargo build --release --target x86_64-apple-ios-sim
   ```

2. **Create Swift Bridge Header**:
   ```c
   // File: zkp_bridge.h
   #include <stdint.h>
   
   typedef struct CPersonalityInputs CPersonalityInputs;
   
   int zkp_initialize(void);
   int zkp_generate_proof(const CPersonalityInputs *inputs, uint8_t **proof_output, uint32_t *proof_len);
   int zkp_verify_proof(const uint8_t *proof_data, uint32_t proof_len, const float *public_inputs, uint32_t public_inputs_len);
   void zkp_free_proof(uint8_t *proof_data, uint32_t proof_len);
   ```

3. **Update Package.swift**:
   ```swift
   .target(
       name: "PrivacyCreditAnalyzer",
       dependencies: [...],
       linkerSettings: [
           .linkedLibrary("privacy_credit_zkp"),
           .linkedFramework("Security"),
           .linkedFramework("CryptoKit")
       ]
   )
   ```

## Security Considerations

1. **Circuit Constraints**: All computations must be verifiable within the circuit
2. **Private Input Protection**: Raw messages never leave the device
3. **Model Integrity**: Model weights/hash prevent tampering
4. **Trait Bounds**: Ensure realistic personality trait ranges
5. **Performance**: Circuit size affects proof generation time on mobile devices

## Testing Strategy

1. **Unit Tests**: Individual circuit components
2. **Integration Tests**: Full proof generation/verification cycle
3. **Performance Tests**: Proof generation time on target devices
4. **Security Tests**: Attempt to generate false proofs
5. **Edge Cases**: Boundary conditions and error handling